# Open NVIDIA X driver — architecture & plan

**Living planning doc.** Goal: replace the closed X-server-side NVIDIA driver with an **open**
driver that drives the GPU through NVIDIA's *generic userspace EGL* stack (the path Wayland
compositors and single-screen EGL apps use), instead of NVIDIA's X-specific blobs.

## Current status (2026-06-23) — read this first on resume

**Phase: planning + tooling. Nothing built or run on real NVIDIA hardware yet.**

Done:
- ABI dependency surface mapped → `NVIDIA-ABI.md` (imports ∪ runtime lookups; watch-list; the
  unexport-PR verdicts/corrections — also posted as tracking comments on the X11Libre PRs).
- **Decisive finding:** `NV-GLX`/`NV-CONTROL` are registered by `nvidia_drv.so` (the DDX) in every
  generation (390/470/550/570) → replacing the DDX **requires reimplementing NV-GLX** (the crux).
- Platform/version support matrix established (below): GBM ≥ ~495; 3-tier model; **start Tier A**.
- **RE tooling built and validated** (`nvglx-re/`): the X11 proxy auto-detects extension opcodes and
  captures requests/replies/events (proven against a live X server on `GLX`/`BIG-REQUESTS`; not yet
  run against a real NVIDIA server).

Immediate next action (needs an NVIDIA box, driver ≥ ~550 for Tier A):
1. `scripts/fetch-nvidia-drivers` (re-extract; the `_WORK_/nvidia/` modules are gitignored/ephemeral).
2. Capture with `nvglx-re/x11trace.py`: a baseline (`glxgears`) + one single-trigger run each
   (`glXCreatePbuffer`, `glXBindTexImageEXT`, …) per `nvglx-re/README.md`.
3. `nvglx-re/analyze.py` + diff → label NV-GLX minor opcodes, record layout here.
4. Then milestone 1: boot Xorg on `nvidia-drm modeset=1` + `modesetting` + glamor (no `nvidia_drv.so`).

Sample drivers used so far: 390.157, 470.256.02, 550.142, 570.133.07.

## The hard constraint (defines the whole design)

> **An unmodified proprietary client `libGL` must keep working — the server must behave as if the
> proprietary X driver were loaded.**

This is not "GLX for generic Mesa clients." The client side stays 100% NVIDIA, so the server must
present the *same protocol surface* the NVIDIA client expects — in particular the private
**`NV-GLX`** extension. That single requirement dictates what we may replace.

## Module map — what we replace vs keep

| Closed module | Role | In the plan |
|---|---|---|
| `nvidia_drv.so` | DDX: modeset/display, **registers `NV-GLX` + `NV-CONTROL`**, screen/visual/fbconfig setup | **REPLACE** (open) |
| `libglxserver_nvidia.so` (470+) | server-side GLX **GLXVND vendor** (the actual GL); self-contained (`libnvidia-glcore`/`tls`/`libc`) | **KEEP** (load under server GLXVND) |
| `libglx.so` (390 only) | server GLX that *wholesale replaces* the server's GLX module | keep, but harder (no clean GLXVND seam) |
| client `libGLX_nvidia` / `libGL` | client GL/GLX | **KEEP, unchanged** (the constraint) |

### Decisive finding (verified via `nm`/`strings` on 390/470/550/570)
`NV-GLX` and `NV-CONTROL` are registered by **`nvidia_drv.so` in every generation** — *never* by
the GLX vendor module. So **replacing the DDX means re-providing `NV-GLX` ourselves.** The GLX
vendor module is independent and can be kept. ⇒ **The crux of this project is reimplementing the
server side of the `NV-GLX` protocol**, not rendering.

## Two-driver split (old vs new) — start with the simpler

The closed stack already splits cleanly by era; mirror that and **start with NEW**:

- **NEW (driver ≳ 495): the simpler one — do this first.**
  - GLX vendor is a **GLXVND module** (`libglxserver_nvidia.so`) — the server keeps its own GLXVND
    host and just loads NVIDIA as a vendor. Clean seam.
  - Buffers via **GBM** (`libnvidia-egl-gbm`) + **DRM-KMS** (`nvidia-drm modeset=1`) — Mesa-shaped.
  - Open DDX ≈ `xf86-video-modesetting` + glamor on NVIDIA EGL, + an `NV-GLX` reimplementation.
- **OLD (driver < 495): harder — defer.**
  - GLX is `libglx.so` *replacing* the server GLX (no GLXVND seam to plug into).
  - No GBM backend → buffers via **EGLDevice + EGLStreams** (`EGL_EXT_platform_device`,
    `EGL_KHR_stream`, `EGL_EXT_output_*`) — stream model, more plumbing.

These can be **two separate xf86 drivers** sharing a common core, picked by detected driver version.

## The 4 building blocks of the open DDX

1. **Modeset / display** — KMS via `nvidia-drm` (`modeset=1` → standard `/dev/dri/cardN`). Reuse
   the `modesetting` DDX's atomic-KMS code.
2. **Buffer allocation** — NEW: **GBM** (scanout + glamor surfaces). OLD: **EGLStreams**.
3. **2D / RENDER acceleration** — **glamor** pointed at NVIDIA `libEGL` (via libglvnd) over GBM.
   Gives accelerated core X / RENDER / Composite.
4. **Client GL** — keep NVIDIA's GLX vendor for the GL itself; **reimplement `NV-GLX`** (pixmap
   lock, pbuffer, framebuffer capture, modeset permission, sideband notification) so the unmodified
   client `libGL` is satisfied. ← the crux.

## The `NV-GLX` problem (make-or-break)

NVIDIA is closed and the `NV-GLX` wire format / minor opcodes are **not public**. Options, worst→best
certainty:
- **Reverse-engineer the wire protocol** (trace client↔server with an Xlib interpose / `x11trace`
  against a real NVIDIA server; correlate with the resource types `nvidia_drv.so` creates: pixmap
  lock, pbuffer). High effort, the real risk to the whole goal.
- **Keep `nvidia_drv.so` loaded *only* for `NV-GLX`** while the open DDX takes over modeset/display
  — if the two can coexist (unclear; `nvidia_drv.so` assumes it owns the screen). Investigate.
- **Negotiate/se if NVIDIA documents it** (`NV-CONTROL` is open via `libXNVCtrl`; `NV-GLX` is not).

**Decision gate:** prototype `NV-GLX` interception/RE early. If a kept NVIDIA GLX vendor + open DDX
can't satisfy the client without a full `NV-GLX` reimpl, the "unchanged libGL" constraint may force
keeping more of the blob than hoped.

## Reference implementations to mine

- **Xwayland** — an X server that already renders via **EGL on NVIDIA** (both **GBM** and
  **EGLStream** backends) and serves **GLX over glamor**. Closest existing blueprint.
- **`xf86-video-modesetting` + glamor** — the open DDX baseline (KMS + glamor + Present).
- **wlroots / mutter / kwin** NVIDIA backends — GBM-vs-EGLStream handling, EGLDevice/EGLOutput.
- **kmscube** — minimal GBM+EGL+KMS sanity example.
- **libglvnd** (`GLX_EXT_libglvnd`), `libnvidia-egl-gbm`, `egl_external_platform` configs.

## Version / platform support matrix

_(from `scripts/nvidia-egl-platforms`; GBM availability sets the NEW-path floor)_

| Version | GBM | Wayland | EGLStream | GLX server model |
|---|---|---|---|---|
| 390.157 | no | yes | yes | **replace-server** (`libglx.so`) |
| 470.256.02 | no | yes | yes | GLXVND vendor |
| 550.142 | **yes** | yes | yes | GLXVND vendor |
| 570.133.07 | **yes** | yes | yes | GLXVND vendor (+ EGL xcb/xlib) |

**Two independent boundaries** (they do *not* coincide) ⇒ three tiers, not two:

- **Tier A — GLXVND vendor + GBM (≈≥495; 550/570 here): START HERE.** Cleanest: server keeps its
  GLXVND host, NVIDIA is just a vendor; buffers via GBM+KMS (Mesa-shaped). Open DDX = modesetting
  + glamor on NVIDIA EGL/GBM + `NV-GLX` reimpl.
- **Tier B — GLXVND vendor + EGLStream only (≈415–470).** Clean GLX seam, but no GBM → buffers via
  EGLStream/EGLDevice. Same DDX as A with a stream buffer backend.
- **Tier C — replace-server `libglx.so` + EGLStream (390 and older).** No GLXVND seam (NVIDIA *is*
  the server GLX) — hardest; defer or skip.

So the "two drivers" split is best drawn as **{A} first, then {B}** (shared DDX core, swappable
buffer backend), with **{C}** a separate question. EGLStream is universal, so it's the portable
buffer fallback; GBM is the simpler path where available.

## ABI relationship

This is the principled exit from the `NVIDIA-ABI.md` constraints: once the **DDX is open and
recompilable**, the unexport/struct-layout rules stop being load-bearing **for the parts the open
DDX uses** — we recompile it. Caveat: while we **keep `libglxserver_nvidia.so`** (a blob), its
imports (`NVIDIA-ABI.md` watch-list) still must hold. Full ABI freedom only after the GLX vendor is
also replaced (out of scope for now — that's reimplementing the GL, not just the protocol).

## Milestones (incremental)

1. **Boot Xorg on NVIDIA with no `nvidia_drv.so`**: `nvidia-drm modeset=1` + stock `modesetting` +
   glamor on NVIDIA EGL/GBM. (Approximate baseline — already partly works; measure it.)
2. **Open DDX skeleton** (fork modesetting) that loads NVIDIA's GLXVND vendor + glamor on GBM.
3. **`NV-GLX` RE / prototype** — trace, implement pixmap-lock + pbuffer first; get one unmodified
   NVIDIA GL client rendering correctly.
4. Fill out `NV-GLX` (fb capture, sideband, modeset perm); Present/swap; multi-output.
5. **OLD-driver variant** (EGLStream + `libglx.so`) once NEW works.
