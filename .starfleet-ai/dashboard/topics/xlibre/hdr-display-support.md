Title: "HDR (High Dynamic Range) display support"
Category: active
Status: "**EDID parser merged; HDR runtime/rendering pipeline still unimplemented.** Resume from a design review, not by rebasing the stale PoC."
Doc-Ref: "Discussion `X11Libre/misc#251`; external WIP fork `cepelinas9000/xserver@wip/x11hdrV2`; branch `wip/hdr-prep` **pushed to `X11Libre/xserver`** (https://github.com/X11Libre/xserver/tree/wip/hdr-prep), tracked locally in agent clone `_WORK_/xserver-master/agent/hdr-prep/xserver` (remote `cepelinas` added there for fetching his branches; extraction base was master commit `cb5f2cd67e`, Feb 17 2026, 871 commits behind current master when analyzed)"
Migrated-From: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
Slug: hdr-display-support

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


## 2026-11-26 live-state refresh

Verified against current GitHub state:

- X11Libre/xserver master HEAD at inspection: 8f47e0e2dd7a9f2dec43acffb2cf0f80b68e5b8e.
- PR [#3216](https://github.com/X11Libre/xserver/pull/3216) is merged (2026-08-24; merge commit 2d72f9e1921a6a0f8d975845c07d7040f6fa8379). Its CTA-861-G Colorimetry (extended tag 5) and HDR Static Metadata (extended tag 6) parsing, xf86Monitor::hdr data and test/ddc-tests.c are present on master.
- xf86DoInterpretHDRMetadata() is declared and implemented, but current code search finds only its declaration, definition and calls from test/ddc-tests.c. There is no production call from the DDC or modesetting EDID path. The old placeholder comment in interpret_edid.c remains. Thus the parser is merged but not integrated into normal server operation.
- No HDR_OUTPUT_METADATA property/API implementation was found in the current X11Libre/xserver source search.
- Remote wip/hdr-prep currently points at 34ad4284c98c8eb3bf049bc762382effb194a14d; it is stale/diverged (2 commits ahead, 587 behind master) and must not be used as a current base without reconciliation.
- The prior wip/hdr-full reconstruction was recorded as local-only on 2026-07-02. No corresponding remote branch exists in X11Libre/xserver now, so it cannot be resumed from the public remote as-is.
- External PoC cepelinas9000/xserver:wip/x11hdrV2 remains at 159a6f484a2a92769787995198f38d80208ec59b (2026-03-14), a single 271-file / +46.5k-line commit against an old base. Its own commit message calls it rough and reports incomplete glamor operation coverage, dark windows and artifacts. Treat as design/source reference only, not a merge candidate.

### Confirmed blockers and design gates

1. **Client protocol:** the PoC repurposes core opcode 125 for a private visual/depth latch. Reject this approach. Design a versioned X extension with explicit capability discovery and request/reply semantics. Define whether colorimetry/transfer metadata attaches to windows, pixmaps or both, inheritance, validation, lifetime and redraw behavior.
2. **RandR/output contract:** define output colorspace selection, HDR static metadata submission, connector capability discovery, hotplug/reconfiguration and SDR fallback. The PoC itself notes its RandR switching support is missing.
3. **Compositing correctness:** the PoC only supports selected glamor operations and reports artifacts/dark windows. Define the complete rendering contract across Render/composite, copy, text, GL/Vulkan clients, and fallback paths. No partial path may silently misrender HDR/SDR content.
4. **Compatibility:** do not accept the PoC's ABI-breaking MAXFORMATS growth, undocumented OpenGL 4.6 minimum, or mandatory Vulkan-header dependency as-is. Keep the existing GL baseline and make any optional backend/build/runtime enablement explicit.
5. **EDID integration safety:** integrate the existing parser only with a non-NULL, complete EDID object. The old local-only reconstruction had a missing-braces path that could call the parser with NULL; explicitly test malformed/short EDID and no-HDR EDID cases.
6. **Validation:** retain the existing captured-EDID tests; add DDC/modesetting integration tests, RandR property/protocol tests, rendering tests for all supported glamor paths, and SDR regression tests. Build both with the feature disabled and enabled.

### Recommended next sequence

- First write/agree a compact normative HDR design: client metadata model, output/RandR contract, color pipeline, fallback/compatibility and security/lifetime rules.
- Then extract only the safe EDID runtime integration as a separate small change, with malformed-EDID tests and no display behavior change.
- Implement output/RandR capability and metadata plumbing next, behind an explicit feature gate.
- Implement the glamor color pipeline end-to-end only after the protocol and output semantics are stable. Do not revive the full PoC as one giant patch.
- Reconstruct the old local-only wip/hdr-full only if its actual patch/commit can be recovered; otherwise use the external PoC plus the old analysis as references and build a fresh branch from current master.


### Design references and unresolved protocol decisions (refreshed 2026-11-26)

Relevant prior design discussion:
- X11Libre organization discussion #251 (Color Management & HDR): https://github.com/orgs/X11Libre/discussions/251
- X11Libre issue #250: https://github.com/X11Libre/misc/issues/250
- Historical X.Org DeepColor extension RFC: https://groups.google.com/g/xorg-devel/c/JmhOVTpZcs8
- Wayland color-management protocol concepts: https://wayland.freedesktop.org/docs/book/Color.html
- Linux DRM/KMS color and HDR output properties: https://docs.kernel.org/gpu/drm-kms.html

Do not simply copy Wayland code or the old DeepColor proposal. Reuse concepts where useful while keeping XLibre's protocol and implementation independent. The historical DeepColor discussion is useful because it explicitly considered API-agnostic drawable metadata and compositor capability discovery; later discussion raised compatibility concerns with adding a new core visual class.

Before implementation, resolve these questions explicitly:
- Pixel representation: is the first supported target packed 10-bpc RGB within the existing 32-bit pixel model, or is FP16 RGBA a required first-class format? Do not conflate bit depth with colorimetry or HDR transfer functions.
- Metadata scope: static image description attached to a window/pixmap versus dynamic/content metadata associated with a presented frame. A single mutable window property is not automatically sufficient for all content.
- Transfer functions: define PQ and HLG support, their reference/peak luminance semantics, and SDR/scRGB conversion. The prior discussion contains competing preferences; no default is approved yet.
- Mixed-client composition: specify how SDR, wide-gamut SDR and HDR surfaces are converted into a common blending space and how the composed output metadata is selected.
- Output policy: define RandR output colorspace and bit-depth selection separately from the KMS HDR_OUTPUT_METADATA blob, which describes the final composed output. The kernel KMS documentation assigns userspace responsibility for blending/tone-mapping mixed layers and supplying final metadata.
- Legacy path: preserve existing 8-bit direct/low-overhead presentation when no color conversion is requested. HDR must not silently force every client through a compositor or Vulkan layer.
- Hardware acceleration: use DRM color-pipeline/overlay capabilities opportunistically, but retain a correct shader/software composition fallback; do not make optional hardware planes a correctness prerequisite.

Suggested first milestone is deliberately narrow: integrate EDID capability discovery into the live output path and expose read-only capabilities, without enabling HDR signaling or changing rendering. This provides a safe, testable base before any client protocol or output-mode switching is added.
