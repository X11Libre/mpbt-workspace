---
title: "HDR (High Dynamic Range) display support"
category: done
status: "**Analysis done, first prep extraction built and pushed** — `wip/hdr-prep` has 2 build-verified commits pulled out of cepelinas9000's WIP, pushed to `X11Libre/xserver` (plain branch, no PR yet) for cross-clone review; the actual rendering pipeline is **not** extracted (see why below)"
doc_ref: "Discussion `X11Libre/misc#251`; external WIP fork `cepelinas9000/xserver@wip/x11hdrV2`; branch `wip/hdr-prep` **pushed to `X11Libre/xserver`** (https://github.com/X11Libre/xserver/tree/wip/hdr-prep), tracked locally in agent clone `_WORK_/xserver-master/agent/hdr-prep/xserver` (remote `cepelinas` added there for fetching his branches; extraction base was master commit `cb5f2cd67e`, Feb 17 2026, 871 commits behind current master when analyzed)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Praetor 2do, 2026-07-01, continued 2026-07-01/07-02: "look at his branches, what exactly he did, pull out prep pieces as
separate PRs." **What's actually in `wip/x11hdrV2`:** one giant unsplit commit ("Reworked X11 HDR", 271 files / +46.5k
lines) against a Feb-17 master base. The huge line count is misleading — **~44k of those lines are the vendored `cglm`
MIT-licensed C math library** (`glamor/hdrext/cglm/`, ~150 header files, wholesale drop-in, not a system dep) plus a
stray `.gdb_history` debug artifact that must never be carried over. The real HDR code is concentrated in
`glamor/hdrext/` (new subdir: `hdrext.c/.h`, shader sources, a draft wire-protocol doc `HDRProto.txt` mirroring Vulkan
structs over X11, `applyvulkanproperties.c`), the **modesetting** driver (`driver.c`, `drmmode_display.c`/`.h`,
`drmmode_bo.c`/`.h` — DRM connector colorspace/HDR-metadata property plumbing), deep **glamor** shader/program
refactoring (`glamor_program.c`, `glamor_render.c`, `glamor_text.c`, etc. — new colorimetry-aware shader variants per
draw op), and EDID/DDC extended-block parsing. **Extracted into `wip/hdr-prep` (2 commits, build-verified `meson setup`
+ `ninja hw/vfb/Xvfb test/tests`, unit test passes via `XLIBRE_TEST=ddc_tests`):** (1) `xfree86: ddc: parse CTA-861-G
HDR static metadata + colorimetry data blocks` — new `xf86DoInterpretHDRMetadata()` walking the EDID CTA extension's
Colorimetry (tag 5) and HDR Static Metadata (tag 6) data blocks into a new tail-appended `xf86Monitor::hdr` field, with
a dedicated unit test (`test/ddc-tests.c`) using 4 real captured hardware EDIDs (Samsung Q800T, MSI MAG321CURV, HP 27
QD, QEMU-virtual-as-negative-case) — this is exactly the "clean extended-EDID-parsing prerequisite" metux asked for back
in January (superseding/complementing the earlier #1881→#1933/#1934/#1935 DDC EDID entry-point work, which didn't cover
CTA HDR/colorimetry blocks). (2) `test: add XLIBRE_TEST env var to select which unit test suites run` — a small, fully
HDR-unrelated test-harness dev-QoL improvement found incidentally in the same commit. Both commits keep cepelinas9000
(`Tautvis <gtautvis@gmail.com>`) as `--author`, with a light typo/whitespace cleanup pass (e.g. `tf_hlf`→`tf_hlg`,
`tradinional`→`traditional`) noted in the commit body — logic untouched. **Why the rendering pipeline itself was NOT
extracted as "prep":** it's genuinely inseparable from the full feature (glamor shader/struct plumbing only makes sense
wired end-to-end), and it surfaces several real design/ABI concerns that need a praetor/upstream call, not a quiet
fixup: (a) `include/misc.h` bumps `MAXFORMATS` 8→10 with cepelinas's own comment *"XXXX breaking ABI XXXX"* — a genuine,
self-admitted ABI break (grows a fixed array inside `ScreenInfo`/related structs); (b) `dix/dispatch.c`+`dix/tables.c`
repurpose core protocol **opcode 125** (previously `ProcBadRequest`) for a "latch visual/depth for this client" hack
(`XXXProcLatchUnlatchVisual`, triggered by sending a sentinel-valued `xCreateWindowReq`-shaped packet) to work around
Vulkan WSI blindly copying the parent window's visual — bypasses the extension mechanism entirely, likely to draw strong
review pushback; (c) `include/glamor.h` bumps the minimum required OpenGL core profile from 3.1 to **4.6** with the
comment *"I didn't check which minimum version required"* — a potentially serious HW-compatibility regression if it ever
landed as-is; (d) additive-only (tail-appended, lower-risk per our ABI precedent) new fields on
`ScreenRec`/`ScrnInfoRec` (the latter correctly placed *after* the existing `reserved*` padding arrays — the one part of
the patch that shows real ABI awareness) plus `GCRec`/`PictureRec`/`ClientRec`, and a new `HDRColor` visual class
constant (`include/colormap.h`, value 6) that doesn't exist in the core X11 protocol; (e) glamor and the whole `hdrext/`
subtree gain a **new build dependency on Vulkan headers** (`#include <vulkan/vulkan.h>` in `hdrext.h`) that isn't
currently a server-side dependency anywhere. None of (a)-(e) are prep-extractable — they need to be resolved as part of
a real design pass on the feature itself. **Other prior-session findings still stand:** `wip/x11hdr`(v1)/`wip/x11hdrV2`
progression, the `__X11HDR_SDR_PARAMS` per-window property, the `VK_xlibre_layer` companion repo, the open PQ-vs-HLG /
per-window-colorspace design threads, the TimothyLottes 8-bit-passthrough objection, and the
`HaplessIdiot`-authored-posts caution — see git history of this row for the full writeup. **Next step:** praetor review
of the two `wip/hdr-prep` commits (pushed as a plain branch, not a PR, per "erstmal in Ruhe anschauen" — deliberately
not opening a PR until reviewed); separately, a praetor/cepelinas conversation on (a)-(e) above before any of the actual
pipeline work is prep-extractable. **2026-07-02: full reconstruction built, local-only, not yet pushed — branch
`wip/hdr-full`** in the same agent clone, one commit on top of `wip/hdr-prep`, reconstructing everything else from
`wip/x11hdrV2` (i.e. what his branch would look like rebased onto the two prep commits + current master) — kept as
faithful as possible, none of (a)-(e) fixed. Needed hand-adaptation for ~870 commits of drift since his Feb-17 base: the
`Xext/<ext>/` reorg (`composite/`→`Xext/composite/`, `dri3/`→`Xext/dri3/`), `dixstruct.h`/`scrnintstr.h` struct fields
re-anchored to the true tail (both structs grew new trailing members upstream since Feb — `saveSets`, an `xfixes`
block), and `glamor_egl.c`'s depth→format helper (renamed/reshaped by the unrelated DRM_FORMAT/GBM_FORMAT consolidation,
issue #2142/PR #2296) — his `bpp`-aware HDR format special-casing was ported onto the new function shape. Dropped the
stray `glamor/hdrext/tests/.gdb_history` debug artifact for good. **Build-verified clean from scratch** (`meson setup
-Dxorg=true -Dtests=false` + full `ninja`, 684/684 targets: `Xorg`, `Xnest`, `Xvfb`, `modesetting_drv.so`,
`libglamoregl.so`, `libglx.so`) — checked `libglamoregl.so`/`modesetting_drv.so`/`libglx.so` for the known
double-compile-into-two-loaded-modules hazard (see "static lib linked into two loadable modules" in `AGENTS.md`): clean,
`HDRExtensionInit` only appears in `libglamoregl.so`. `-Dtests=false` was needed because `glamor/hdrext/tests/` pulls in
`criterion`, unavailable/not installable (no root) in this sandbox — cepelinas's own unit tests are therefore **not yet
verified**, only the main build. **Found a real bug while reconstructing** (left in, not fixed, per "faithful
reproduction" — flagging instead): `drmmode_output_get_modes()` in `drmmode_display.c` has `if (mon && edid_blob->length
> 128)\n mon->flags|= ...;\n xf86DoInterpretHDRMetadata(mon);` — missing braces mean the HDR-metadata call is **not
actually guarded by the `if`**, so it runs even when `xf86InterpretEDID()` returned NULL for a malformed EDID, and
`xf86DoInterpretHDRMetadata()` dereferences unconditionally — a likely NULL-deref crash on a bad EDID. Caught by GCC's
`-Wmisleading-indentation` while building the modesetting driver.
