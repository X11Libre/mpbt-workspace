#!/usr/bin/env python3
"""
Analyze an NV-GLX capture (JSONL from x11trace.py --jsonl) to help infer the
wire format: per (ext, kind, minor/code) it reports counts, length stats,
request<->reply pairing, and a per-byte-offset value table that highlights
which offsets are CONSTANT (likely opcode/pad/fixed) vs VARYING (likely
ids/lengths/params). That contrast is the main lever for guessing field layout.

Usage:
  python3 analyze.py cap.jsonl
  python3 analyze.py cap.jsonl --minor 3      # focus one request minor opcode
"""
import argparse, json, collections, sys


def load(path):
    recs = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                recs.append(json.loads(line))
    return recs


def col_table(blobs, maxlen=64):
    """For a set of equal-ish byte blobs, show per-offset constant/varying."""
    n = min(maxlen, max((len(bytes.fromhex(b)) for b in blobs), default=0))
    cols = []
    for off in range(n):
        vals = set()
        for b in blobs:
            raw = bytes.fromhex(b)
            if off < len(raw):
                vals.add(raw[off])
        if len(vals) == 1:
            cols.append(f'{next(iter(vals)):02x}')        # constant
        else:
            cols.append('..')                              # varying
    return cols


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('jsonl')
    ap.add_argument('--minor', type=int, default=None)
    ap.add_argument('--ext', default=None)
    args = ap.parse_args()
    recs = load(args.jsonl)
    if not recs:
        print('empty capture'); return

    groups = collections.defaultdict(list)
    for r in recs:
        if args.ext and r.get('ext') != args.ext:
            continue
        key = (r.get('ext'), r['what'], r.get('minor') if r.get('minor') is not None else r.get('code'))
        groups[key] = groups.get(key, [])
        groups[key].append(r)

    print(f'# {len(recs)} records, {len(groups)} (ext,kind,op) groups\n')
    for key in sorted(groups, key=lambda k: (str(k[0]), k[1], k[2] if k[2] is not None else -1)):
        ext, what, op = key
        rs = groups[key]
        lens = [r['length'] for r in rs]
        lc = collections.Counter(lens)
        print(f'== {ext}  {what}  op/minor={op}  n={len(rs)}  '
              f'len={"fixed "+str(lens[0]) if len(lc)==1 else dict(lc)} ==')
        if args.minor is not None and op != args.minor:
            continue
        cols = col_table([r['hex'] for r in rs])
        # print offsets 0..len in rows of 16
        for i in range(0, len(cols), 16):
            chunk = cols[i:i+16]
            idx = ' '.join(f'{i+j:2d}' for j in range(len(chunk)))
            val = ' '.join(f'{c:>2}' for c in chunk)
            print(f'   off {idx}')
            print(f'   val {val}')
        print('   (.. = byte varies across samples = likely id/len/param; '
              'hex = constant = likely opcode/pad)\n')

    # request<->reply size correlation
    reqs = {(r['ext'], r['seq']): r for r in recs if r['what'] == 'request'}
    pairs = [(reqs[(r['ext'], r['seq'])], r) for r in recs
             if r['what'] == 'reply' and (r['ext'], r['seq']) in reqs]
    if pairs:
        print('== request -> reply pairs (minor : req_len -> reply_len) ==')
        seen = collections.Counter()
        for q, a in pairs:
            seen[(q.get('minor'), q['length'], a['length'])] += 1
        for (minor, ql, al), n in sorted(seen.items()):
            print(f'   minor={minor}  {ql} -> {al}   (x{n})')


if __name__ == '__main__':
    main()
