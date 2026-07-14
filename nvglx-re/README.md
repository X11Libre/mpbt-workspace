# NV-GLX wire-protocol RE tooling

Tools to reverse-engineer NVIDIA's private **NV-GLX** (and **NV-CONTROL**) X11 extensions, so the
open X driver (`../NVIDIA-OPEN-DDX.md`) can re-provide the server side that an **unmodified
proprietary `libGL`** expects. This is **interoperability** RE of an undocumented protocol — no
NVIDIA code is included, copied, or modified; we only observe the wire.

## Pieces

- **`x11trace.py`** — transparent X11 proxy. Forwards bytes verbatim (the session works normally)
  and observes: parses the setup, counts request sequence numbers, **auto-detects the major
  opcode / first_event / first_error** assigned to NV-GLX & NV-CONTROL by sniffing
  `QueryExtension`, and logs every matching request/reply/event/error with minor opcode, length,
  request↔reply correlation, and hex dump. `--jsonl` writes a structured capture.
- **`analyze.py`** — reads the JSONL and prints, per (ext, kind, minor): counts, length stats,
  request→reply size pairing, and a **per-byte-offset constant-vs-varying table** (the main lever
  for guessing field layout).

## Why a proxy (not just `xtrace`)

`xtrace`/`xscope` are great for a quick look, but for RE we want **structured, diffable** output
and reliable reply/event correlation for an *unknown* extension. `x11trace.py` auto-detects the
opcode and emits JSONL so `analyze.py` can do field inference and you can diff captures across
controlled triggers. (Still worth running `xtrace` once as a cross-check.)

## Setup (needs a real NVIDIA X server)

The proxy creates a second X display (`:9`) that relays to the real one (`:0`). Forwarding the
client's auth verbatim means the cookie must be valid for the **real** server:

```sh
# allow the proxy session to reach :0 (pick ONE):
xhost +SI:localuser:$USER                      # simplest, local only
# or copy the :0 cookie to :9:
#   xauth add :9 . $(xauth list :0 | awk 'NR==1{print $3}')

# start the tracer: proxy :9 -> real :0, capture to cap.jsonl
python3 x11trace.py --listen :9 --real :0 --jsonl cap.jsonl

# in another shell, run a GL client THROUGH the proxy:
DISPLAY=:9 glxgears
DISPLAY=:9 <your GL app that exercises the op you want to map>
```

`x11trace.py` prints the detected `NV-GLX: major_opcode=… first_event=… first_error=…` as soon as
the client calls `QueryExtension`, then dumps each NV-GLX message.

## Mapping minor opcodes → operations (the method)

NV-GLX minor opcodes are unlabeled; you map them by **exercising one operation at a time** and
seeing which minor opcode fires. From the strings in `nvidia_drv.so`, the NV-GLX surface is roughly:

| NV-GLX feature (string) | Trigger to exercise it |
|---|---|
| `pixmap lock` | `glXBindTexImageEXT` / `GLX_EXT_texture_from_pixmap` (composite a redirected window, or bind a pixmap to a texture) |
| `pbuffer` | `glXCreatePbuffer` + make-current + render |
| `framebuffer capture` | NvFBC / screen-capture path (e.g. the capture SDK sample) |
| `modeset permission` | mode set / VR-direct / lease-like ops |
| `sideband client notification` | GL⇄CL/VDPAU/NVENC interop, `glWaitSync` across APIs (see the NVIDIA devforum NV-GLX thread) |

Procedure:

1. Baseline: `DISPLAY=:9 glxgears` — capture context create / make-current / swap. Label those
   minor opcodes.
2. One trigger per capture (fresh `--jsonl` file each), e.g. only-pbuffer, only-bindteximage.
3. `python3 analyze.py cap_pbuffer.jsonl` — note which minor opcode is new vs the baseline; read
   the constant/varying byte table to guess fields (constant low bytes near the front = the
   sub-opcode/pad; varying 4-byte groups = XIDs / sizes / handles).
4. Vary one input (e.g. pbuffer width) and diff captures to pin which offset carries it.
5. Write the hypothesized layout into `../NVIDIA-OPEN-DDX.md` and validate by having the open DDX
   answer that request and checking the client proceeds.

## Optional correlation aid

To tie app-level GLX calls to wire ops, an `LD_PRELOAD` shim over the **libglvnd** entry points
(`glXCreatePbuffer`, `glXBindTexImageEXT`, `glXMakeCurrent`, `glXSwapBuffers`, …) can timestamp
calls to stderr; line them up with the proxy's timestamps. (libglvnd is open, so interposing its
public entry points is clean — we don't touch NVIDIA's vendor lib.) Not included yet; add under
this dir if useful.

## Limitations / honesty

- Minor-opcode *semantics* are inferred, not authoritative — NVIDIA's format is unpublished.
- Encrypted/opaque handles (GPU VA, RM object ids) will look like random 4/8-byte fields; we can
  learn their *position/size*, not their meaning, from the wire alone.
- The bulk GPU data path is **not** on the X wire (it's the kernel channel — see `../NVIDIA-ABI.md`);
  NV-GLX only carries coordination, which is exactly what the open DDX must reproduce.
