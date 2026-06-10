#!/usr/bin/env python3
"""
NV-GLX wire-protocol tracer — a transparent X11 proxy for reverse-engineering
NVIDIA's private NV-GLX (and NV-CONTROL) X extensions, for building an
interoperable open X driver.

It sits between an unmodified NVIDIA GL client and the real X server, forwards
bytes verbatim (so the session works normally), and *observes* the stream:

  * parses the X11 connection setup (byte order, past auth) on both directions
  * counts client request sequence numbers
  * sniffs QueryExtension request/reply pairs to AUTO-DETECT the major opcode,
    first_event and first_error assigned to "NV-GLX" / "NV-CONTROL"
  * logs every NV-GLX (and NV-CONTROL) request / reply / event / error with
    minor opcode, length, request<->reply correlation, and a hex+ascii dump
  * emits JSONL (--jsonl) for offline analysis (see analyze.py)

Forwarding is decoupled from parsing: bytes are relayed as soon as they arrive,
and parsing runs on a copy. A parser bug can mis-log but never desync the pipe.

Usage:
  python3 x11trace.py --listen :9 --real :0 [--jsonl cap.jsonl] [--also NV-CONTROL]
then run the GL client with DISPLAY=:9  (see README.md for Xauth setup).

This is interoperability reverse engineering of an undocumented protocol; no
NVIDIA code is included or modified.
"""
import argparse, json, os, selectors, socket, struct, sys, time

CORE_QUERY_EXTENSION = 98

def hexdump(b, width=16):
    out = []
    for i in range(0, len(b), width):
        chunk = b[i:i+width]
        hexs = ' '.join(f'{c:02x}' for c in chunk)
        asc = ''.join(chr(c) if 32 <= c < 127 else '.' for c in chunk)
        out.append(f'    {i:04x}  {hexs:<{width*3}}  {asc}')
    return '\n'.join(out)


class Side:
    """Accumulating parser for one direction of one connection."""
    def __init__(self, conn, direction):
        self.conn = conn          # parent Conn (shared state)
        self.dir = direction      # 'c2s' or 's2c'
        self.buf = bytearray()
        self.in_setup = True

    def feed(self, data):
        self.buf += data
        try:
            if self.dir == 'c2s':
                self._parse_c2s()
            else:
                self._parse_s2c()
        except Exception as e:                       # never let parsing kill the pipe
            self.conn.log_err(f'parser desync ({self.dir}): {e!r} — disabling parse')
            self.buf.clear()
            self.feed = lambda *_: None

    # ---- client -> server ----
    def _parse_c2s(self):
        c = self.conn
        if self.in_setup:
            if len(self.buf) < 12:
                return
            bo = self.buf[0]
            c.endian = '<' if bo == 0x6c else '>'    # 'l' little, 'B' big
            n = struct.unpack_from(c.endian + 'H', self.buf, 6)[0]   # auth name len
            d = struct.unpack_from(c.endian + 'H', self.buf, 8)[0]   # auth data len
            total = 12 + ((n + 3) & ~3) + ((d + 3) & ~3)
            if len(self.buf) < total:
                return
            del self.buf[:total]
            self.in_setup = False
        E = c.endian
        while len(self.buf) >= 4:
            opcode = self.buf[0]
            minor = self.buf[1]
            length = struct.unpack_from(E + 'H', self.buf, 2)[0]
            if length == 0:                           # BigRequests
                if len(self.buf) < 8:
                    return
                length = struct.unpack_from(E + 'I', self.buf, 4)[0]
            nbytes = length * 4
            if nbytes == 0 or len(self.buf) < nbytes:
                return
            req = bytes(self.buf[:nbytes])
            del self.buf[:nbytes]
            c.seq = (c.seq + 1) & 0xffffffff          # this request's sequence number
            self._on_request(opcode, minor, req)

    def _on_request(self, opcode, minor, req):
        c = self.conn
        if opcode == CORE_QUERY_EXTENSION:
            nlen = struct.unpack_from(c.endian + 'H', req, 4)[0]
            name = req[8:8+nlen].decode('latin1')
            c.pending_qe[c.seq & 0xffff] = name
        elif opcode in c.watch_opcodes:
            c.pending_reply[c.seq & 0xffff] = (opcode, minor)
            c.record('request', opcode=opcode, minor=minor, seq=c.seq, data=req)

    # ---- server -> client ----
    def _parse_s2c(self):
        c = self.conn
        if self.in_setup:
            if len(self.buf) < 8:
                return
            status = self.buf[0]
            addlen = struct.unpack_from(c.endian + 'H', self.buf, 6)[0]
            total = 8 + addlen * 4
            if status == 2:        # authenticate: reason string of addlen*4 bytes follows header
                total = 8 + addlen * 4
            if len(self.buf) < total:
                return
            del self.buf[:total]
            self.in_setup = False
        E = c.endian
        while len(self.buf) >= 32:
            kind = self.buf[0]
            extra = 0
            if kind == 1 or kind == 35:               # Reply or GenericEvent: 32 + len*4
                rlen = struct.unpack_from(E + 'I', self.buf, 4)[0]
                extra = rlen * 4
            total = 32 + extra
            if len(self.buf) < total:
                return
            msg = bytes(self.buf[:total])
            del self.buf[:total]
            self._on_reply_or_event(kind, msg)

    def _on_reply_or_event(self, kind, msg):
        c = self.conn
        E = c.endian
        if kind == 1:                                  # Reply
            seq = struct.unpack_from(E + 'H', msg, 2)[0]
            name = c.pending_qe.pop(seq, None)
            if name is not None:                       # QueryExtension reply -> learn opcodes
                present = msg[8]
                major = msg[9]; first_event = msg[10]; first_error = msg[11]
                if present and name in c.want_ext:
                    c.ext[name] = (major, first_event, first_error)
                    c.watch_opcodes.add(major)
                    c.watch_events[first_event] = name
                    c.watch_errors[first_error] = name
                    c.log_info(f'{name}: major_opcode={major} first_event={first_event} '
                               f'first_error={first_error}')
                return
            rq = c.pending_reply.pop(seq, None)
            if rq is not None:
                op, minor = rq
                c.record('reply', opcode=op, minor=minor, seq=seq, data=msg)
        elif kind == 0:                                # Error
            code = msg[1]
            if code in c.watch_errors:
                seq = struct.unpack_from(E + 'H', msg, 2)[0]
                c.record('error', code=code, ext=c.watch_errors[code], seq=seq, data=msg)
        else:                                          # Event (2..34) or GenericEvent(35)
            code = kind & 0x7f
            if code in c.watch_events:
                c.record('event', code=code, ext=c.watch_events[code], data=msg)


class Conn:
    _ids = 0
    def __init__(self, want_ext, sink):
        Conn._ids += 1
        self.id = Conn._ids
        self.endian = '<'
        self.seq = 0
        self.pending_qe = {}        # seq16 -> ext name (QueryExtension in flight)
        self.pending_reply = {}     # seq16 -> (opcode, minor) for watched requests
        self.want_ext = set(want_ext)
        self.ext = {}               # name -> (major, first_event, first_error)
        self.watch_opcodes = set()
        self.watch_events = {}      # first_event -> name
        self.watch_errors = {}      # first_error -> name
        self.want_ext_qe = {}
        self.sink = sink

    def log_info(self, m): self.sink.info(self.id, m)
    def log_err(self, m): self.sink.info(self.id, '!! ' + m)
    def record(self, what, **kw):
        self.sink.record(self.id, what, self.ext, **kw)


class Sink:
    def __init__(self, jsonl_path):
        self.jl = open(jsonl_path, 'w') if jsonl_path else None
        self.t0 = time.time()
    def info(self, cid, msg):
        print(f'[conn {cid}] {msg}', file=sys.stderr, flush=True)
    def record(self, cid, what, ext, opcode=None, minor=None, code=None,
               seq=None, data=b'', ext_name=None):
        # name the extension from opcode/code
        name = ext_name
        if name is None:
            for n, (maj, fe, fr) in ext.items():
                if opcode == maj or code in (fe, fr):
                    name = n; break
        rec = dict(what=what, ext=name, opcode=opcode, minor=minor, code=code,
                   seq=seq, length=len(data), hex=data.hex())
        if self.jl:
            self.jl.write(json.dumps(rec) + '\n'); self.jl.flush()
        head = f'[conn {cid}] {what.upper():7} {name or "?"}'
        if minor is not None: head += f' minor={minor}'
        if code is not None: head += f' code={code}'
        if seq is not None: head += f' seq={seq}'
        head += f' len={len(data)}'
        print(head, file=sys.stderr)
        print(hexdump(data), file=sys.stderr, flush=True)


def real_target(disp):
    disp = disp or os.environ.get('DISPLAY', ':0')
    if disp.startswith('/') or '/' in disp:           # explicit path
        return ('unix', disp)
    host, _, num = disp.partition(':')
    num = num.split('.')[0]
    if host in ('', 'unix'):
        return ('unix', f'/tmp/.X11-unix/X{num}')
    return ('tcp', (host, 6000 + int(num)))


def listen_socket(disp):
    num = disp.lstrip(':').split('.')[0]
    path = f'/tmp/.X11-unix/X{num}'
    try: os.unlink(path)
    except FileNotFoundError: pass
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.bind(path); s.listen(8); s.setblocking(False)
    return s, path


def connect_real(target):
    fam, addr = target
    if fam == 'unix':
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect(addr)
    else:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(addr)
    s.setblocking(False)
    return s


def main():
    ap = argparse.ArgumentParser(description='NV-GLX X11 wire tracer (RE proxy)')
    ap.add_argument('--listen', default=':9', help='proxy display to create (default :9)')
    ap.add_argument('--real', default=None, help='real display (default $DISPLAY or :0)')
    ap.add_argument('--jsonl', default=None, help='write structured capture to this JSONL file')
    ap.add_argument('--also', action='append', default=[],
                    help='additional extension name to watch (repeatable; NV-GLX always watched)')
    args = ap.parse_args()

    want = ['NV-GLX', 'NV-CONTROL'] + args.also
    target = real_target(args.real)
    sink = Sink(args.jsonl)
    lsock, lpath = listen_socket(args.listen)
    sink.info(0, f'listening on {args.listen} ({lpath}) -> real {target}; watching {want}')

    sel = selectors.DefaultSelector()
    sel.register(lsock, selectors.EVENT_READ, ('accept', None))
    peers = {}     # fileno -> (peer_sock, side_parser)

    def close_pair(a, b):
        for s in (a, b):
            try: sel.unregister(s)
            except Exception: pass
            try: s.close()
            except Exception: pass
            peers.pop(s.fileno() if not s._closed else -1, None)

    while True:
        for key, _ in sel.select():
            tag, _ = key.data if isinstance(key.data, tuple) else ('io', None)
            if key.fileobj is lsock:
                cli, _ = lsock.accept(); cli.setblocking(False)
                try:
                    srv = connect_real(target)
                except OSError as e:
                    sink.info(0, f'cannot reach real display: {e}'); cli.close(); continue
                conn = Conn(want, sink)
                c2s = Side(conn, 'c2s'); s2c = Side(conn, 's2c')
                peers[cli.fileno()] = (srv, c2s)
                peers[srv.fileno()] = (cli, s2c)
                sel.register(cli, selectors.EVENT_READ, ('io', None))
                sel.register(srv, selectors.EVENT_READ, ('io', None))
                continue
            sock = key.fileobj
            ent = peers.get(sock.fileno())
            if not ent:
                continue
            peer, parser = ent
            try:
                data = sock.recv(65536)
            except (BlockingIOError, InterruptedError):
                continue
            except OSError:
                data = b''
            if not data:
                close_pair(sock, peer); continue
            try:
                peer.sendall(data)        # forward verbatim FIRST
            except OSError:
                close_pair(sock, peer); continue
            parser.feed(data)             # then observe


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
