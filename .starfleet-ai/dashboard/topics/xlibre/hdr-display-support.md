Title: "HDR (High Dynamic Range) display support"
Category: active
Status: "**EDID parser merged; bounded read-only capability integration is in Draft PR #4240; HDR runtime/rendering pipeline still unimplemented.** Continue from current master and the design gates, not the stale PoC."
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


### Proposed implementation baseline (discussion draft; not normative yet)

Keep source-image description and output signaling separate:

- **Source image description:** immutable, versioned description of primaries, white point, transfer function, reference white and luminance range. Associate it with a drawable/window for static content semantics. If dynamic metadata is needed, attach it to a frame/presentation transaction rather than racing mutable window properties.
- **Output description:** separate per-output capabilities and selected output mode/colorspace/bit depth. Read sink capabilities from EDID; select an output encoding only when the sink and DRM driver support it.
- **Composition:** convert source content into a common linear-light working space before blending. Tone-map mixed SDR/HDR or mismatched peak luminance deliberately; then encode the final composed frame for the output. Do not blend PQ/HLG encoded samples directly.
- **KMS handoff:** modesetting submits the final composed frame's metadata through the DRM connector HDR_OUTPUT_METADATA blob and sets supported Colorspace/max_bpc properties. Do not copy the monitor's EDID static metadata blob straight to HDR_OUTPUT_METADATA: one describes sink capability, the other describes the outgoing composed frame.
- **Compatibility:** preserve the current 8-bit direct path when no color transform is required. Avoid mandatory Vulkan, a forced external compositor, a new core visual class, or a global GL 4.6 minimum.

Recommended format strategy (requires owner approval): start with existing packed 10:10:10:2 / 30-bit TrueColor-compatible output where supported; use floating-point intermediate buffers internally when available. Treat client-visible FP16 RGBA as a later capability, not a prerequisite for first HDR10 output. PQ is a practical first transfer-function target because of display support; define HLG semantics in the model rather than silently treating it as PQ.

Suggested milestones:

0. Read-only EDID capability integration and diagnostics; no modeset or rendering behavior changes.
1. Explicit experimental output mode behind a runtime option; negotiate DRM Colorspace/max_bpc and HDR_OUTPUT_METADATA, with safe disable/rollback and SDR fallback.
2. Versioned client color-description API and mixed SDR/HDR source conversion; no core protocol opcode reuse.
3. Complete glamor path coverage, dynamic metadata where needed, advanced formats and optional hardware color-pipeline/plane offload.

Each milestone needs tests for no-HDR EDID, malformed/short EDID, unsupported KMS properties, hotplug, SDR-only clients, mixed SDR/HDR, and unchanged legacy 8-bit pass-through.


## 2026-11-26 — dedicated HDR session owner decisions

The owner approved these design directions; see `metux/wormhole-0:master/X11LIBRE_HDR_COLOR_MANAGEMENT_SPEC.md` sections 24–25 for the detailed rationale and remaining open items:

- Common compositor working space: linear BT.2020 / D65, output-independent, neutral RGB 1.0 = 203 cd/m².
- Negotiated compositor handoff: RGBA FP16, linear premultiplied alpha; capability negotiation and a valid fallback remain mandatory.
- Unmanaged legacy windows: implicit sRGB/D65 source profile. In the HDR color-managed composition path, the session-wide configurable `LegacySDRReferenceWhite` defaults to 203 cd/m² so SDR graphics white is anchored to HDR reference white. 80 or 100 cd/m² remain user/session-configurable alternatives.
- The legacy reference-white setting is never per-output; explicit Color Descriptions override it.
- Exact configuration interface/range, HLG absolute-luminance assumptions, non-finite FP policy and wire ABI remain open. Chromatic adaptation is owner-decided in section 26. No Xserver implementation is authorized by these design decisions.

The earlier suggested format strategy in this tracker predates owner approval of the negotiated FP16 compositor handoff and should be read as historical discussion, not as the current owner-approved direction.


### 2026-11-26 — chromatic adaptation decisions approved

Owner approval received for all three v1 decisions:
- Fixed ICC linear Bradford for relative-colorimetric RGB sources whose white point differs from D65.
- Full adaptation only; no partial-adaptation control or per-window/per-output CAT selector.
- Explicit, versioned distinction between relative-colorimetric RGB and absolute-colorimetric XYZ / already-adapted PCS semantics, preventing double adaptation.

The approved source pipeline and validation requirements are recorded in spec section 26 and durable decision `metux/wormhole-0/decisions/2026-11-26--hdr-linear-bradford-and-source-semantics.md`. The spec and project context now mark these decisions as approved.

Remaining design work: validation tolerances and canonical white-point precision, HLG luminance semantics, and non-finite FP16 handling. Owner has approved parametric Color Descriptions only in v1; arbitrary ICC profiles/CMM integration are deferred. No Xserver implementation changed and no wire ABI is frozen.


### 2026-11-26 — v1 Color Description scope and no-compositor output proposal

**Owner-approved scope:** v1 supports parametric Color Descriptions only (primaries, white point, transfer function, luminance/reference-white semantics and relative/absolute interpretation). Arbitrary ICC profile ingestion and general-purpose CMM integration are deferred beyond v1. Specification section 26.6 records the decision.

**New design proposal (not yet approved):** when no compositor is active, convert the final desktop image independently per output, preferably through per-CRTC DRM/KMS color-pipeline blocks; otherwise use output-specific GPU scanout buffers, with a safe SDR fallback. This must remain separate from per-window conversion into the common compositor working space. Multi-output behavior, source-semantic limitations, Present/direct-scanout and overlay/cursor/video-plane handling need investigation. See specification section 27.

### 2026-11-26 — modesetting audit and NVIDIA compatibility gate

X11Libre/xserver master was refreshed at `bb06f6ddca766c41c81494ae228c11e53df59590`. The current modesetting DDX has CRTC `GAMMA_LUT`, `GAMMA_LUT_SIZE` and `CTM` handling, but no `DEGAMMA_LUT` in its CRTC property model. Its 1D RGB gamma LUT is enabled only when the kernel reports a usable size (default policy up to 4096 entries, overridable with `UseGammaLUT`); otherwise it uses the legacy DRM CRTC gamma call. CTM is separate 3x3 state. This is not a full HDR pipeline.

Present checks format/modifier support across all active CRTCs before flipping; hardware cursor programming is separate, and sprite/overlay visibility affects flip eligibility. Shared screen-pixmap and per-CRTC scanout behavior still needs deeper multi-output/PRIME/clone testing.

**Owner requirement:** proprietary NVIDIA Xorg driver must not be broken; it does not have to support HDR. Keep HDR opt-in and runtime capability-gated, preserve legacy SDR/X11 behavior when unsupported, avoid mandatory new driver callbacks or unreviewed public driver ABI changes, and keep DRM/GBM/Vulkan requirements out of generic DIX/core. Do not raise the global OpenGL baseline. Legacy Composite/Damage/Present/DRI3/RandR gamma and scanout semantics must remain unchanged unless the new contract is negotiated.

The proprietary NVIDIA DDX is external to X11Libre/xserver and was not inspected/tested. Treat it as a required compatibility test target, not as verified. Detailed findings/test gates are in spec section 28; durable decision: `metux/wormhole-0/decisions/2026-11-26--hdr-driver-compatibility-and-nvidia.md`. No Xserver code changed; no implementation authorized.


Additional multi-CRTC finding: modesetting's ordinary screen pixmap uses a shared front buffer; each CRTC has its own scanout origin, and PRIME can select per-CRTC scanout pixmaps. KMS gamma-LUT/CTM state is CRTC-scoped, so cloned connectors on one CRTC share it; independent connector transforms cannot be assumed. Hardware cursor operations are separate. Present requires candidate format/modifier support across every active CRTC. Do not make FP16 the mandatory screen-pixmap format. See spec section 28.7.


### 2026-11-26 — ScreenRec private operations / NVIDIA ABI audit

Owner preference: add future HDR screen/backend operations through DIX private state, not by extending ScreenRec. Use a core-owned key of the existing PRIVATE_SCREEN type and a core-owned private record with a copied, versioned optional ops table. `ScreenRec.devPrivate` is the legacy single DDX pointer and must not be overwritten; `devPrivates` is the DIX-managed key store. Do not add a DevPrivateType / change PRIVATE_LAST because `screenSpecificPrivates[PRIVATE_LAST]` is embedded in ScreenRec and affects its layout. `dixRegisterPrivateKey()` handles existing regular and GPU screens via `fixupScreens()`.

NVIDIA compatibility is particularly sensitive: CONFIG_LEGACY_NVIDIA_PADDING adds `reserved_for_nvidia_470_and_390` at a fixed ScreenRec position; Meson option `legacy_nvidia_padding` controls it; Video ABI is 28.1 with padding vs 28.0 without; LoaderGetABIVersion reports NVIDIA ABI 25.2 under the compatibility configuration. `dix/pixmap.c` initializes the field NULL. Preserve the padding, field position, initialization and loader logic. `legacy_nvidia_340x` is a separate old-entrypoint option. Proprietary NVIDIA need not implement HDR; no registration must mean legacy SDR operation.

See spec section 29 and durable decision `metux/wormhole-0/decisions/2026-11-26--hdr-screen-private-ops-and-nvidia-abi.md`. Source base `X11Libre/xserver:master` at `3132e4b7997b525d046e727c1db6656d14b5bc20`. No source code changed; no implementation authorized.


## 2026-11-26 — Core / DDX / Glamor interface design

Xserver `master` was rechecked at `3132e4b7997b525d046e727c1db6656d14b5bc20`. Glamor uses its own `PRIVATE_SCREEN` state and X-depth-derived pixmap/FBO formats; its current DRI3 export is tied to `PixmapPtr`. Desktop GL 2.1 / GLES 2.0 remain the current initialization baselines, so FP16 FBO renderability and shader precision require runtime probes.

A design proposal was added to `metux/wormhole-0:master/X11LIBRE_HDR_COLOR_MANAGEMENT_SPEC.md`, section 30 (commit `e845da71c89f60ddf10526bb3065594ce6753427`), and summarized in `X11LIBRE_HDR_PROJECT_CONTEXT.md` (commit `5e47282ff3cac80dc416c451b77d76c12f3b3156`).

Key direction:
- DIX/core owns policy, per-window source/transformed generations and negotiation.
- A core-owned optional versioned per-screen provider is attached through existing `PRIVATE_SCREEN` state; no ScreenRec/DevPrivateType changes.
- The first in-tree provider may be modesetting only and delegates GPU transformation to Glamor.
- Glamor uses a separate opaque FP16 color-buffer object, not a fake X pixmap depth.
- Buffer transport and synchronization are backend capabilities; DRI3 is not the color semantics API.
- Runtime-probe FP16 FBO, shader precision, import/export, dimensions and end-to-end synchronization without raising the GL baseline.
- Legacy Composite/SDR behavior remains unchanged unless the versioned handoff is explicitly negotiated. NVIDIA need not register or support HDR.
- No Xserver code changed; implementation remains unauthorized. Exact provider API, transport/wire contract, source-path coverage, tiling and failure transitions remain open.


Follow-up source audit of modesetting `driver.c` at Xserver HEAD `3132e4b7997b525d046e727c1db6656d14b5bc20`:
- modesetting loads the Glamor EGL module dynamically with `xf86LoadSubModule()` and resolves symbols with `LoaderSymbolFromModule()`; per-screen function pointers are stored in `modesettingRec`.
- HDR helpers must be optional symbols, resolved separately. Existing `glamor_gbm` is not proof of FP16 renderability/export or compositor synchronization.
- The provider must quiesce/unregister in the early modesetting `CloseScreen()` path before BO/GBM teardown and before the wrapped Glamor close chain; no callbacks may survive `FreeScreen()`.
- Missing helper symbols or failed feature probes mean HDR unavailable, not DDX initialization failure.

Detailed lifecycle constraints are in spec section 30.9, follow-up commit `02770890c38c71304c04330e7cf08f79478af6c6`. No Xserver source changes.


Owner clarification: modesetting DDX and Glamor module are always built and deployed together from the same codebase. Therefore their internal HDR helper interface is a same-build interface, not an independently versioned optional module ABI. Required helper symbols can be resolved as part of the paired module contract; missing symbols mean a broken/mismatched installation, not normal runtime HDR unavailability. No optional-symbol compatibility shim is needed. Runtime HDR remains optional per screen based on FP16/shader/export/synchronization probes. Generic core remains Glamor-independent; NVIDIA remains legacy SDR unless it separately implements a provider. Specification update: `metux/wormhole-0` commit `49303af27f6e059caebfce1c36da15769a1f963b`; project-context update commit `c62da5fae17b59e2e9ee8143318fe3d580343fbc`.


Follow-up design review (Xserver master `3132e4b7997b525d046e727c1db6656d14b5bc20`): Glamor's EGL private state owns the EGL context and GBM device; modesetting borrows that same GBM device via `glamor_egl_get_gbm_device()`. Glamor already has DMA-BUF export paths and `glamor_egl_flush_fence_fd()` for producer native-fence export. Recommended split: core tracks logical generations only; modesetting owns the optional per-screen provider/orchestration; Glamor owns opaque FP16 physical buffers (GBM BO/EGLImage/texture/FBO), export and fence import/wait; the negotiated Composite extension transports FDs and compositor release. Do not duplicate GBM allocation in modesetting, require scanout usage for compositor-only buffers, or treat existing DRI3 syncobj support as proof of the new sync contract. Descriptor must include FourCC/modifier/dimensions/per-plane FD/stride/offset. Exact FP16 DRM format and both fence directions remain to be tested. Spec section 30.10 committed as `5cb70e943dd77d791e96162d85dc8b1dd1b0a1be`; project context commit `b53f89914a526bdcc91dc2184a5ef5dd650d7b69`. No Xserver source changes or implementation authorization.


FP16 DMA-BUF format candidate: `DRM_FORMAT_ABGR16161616F` (little-endian A:B:G:R 16-bit float components, yielding R/G/B/A component order in memory) is a candidate for the agreed RGBA FP16 handoff. It is not yet fixed: GL renderability, GBM allocation/modifier support, export, compositor import and alpha/channel interpretation must be verified; big-endian and alternative formats remain open. Spec commit `1e7ce056f3277694bd1c2841c048467641e893e9`; context commit `a128a086cdee0c014b40a4994824c029496c75aa`.


Buffer-generation / synchronization follow-up: Specification section 30.11 now separates immutable logical content generations from reusable physical Glamor allocations. A published buffer remains leased until the compositor returns exactly one generation-correlated release fence; Glamor imports it and queues a GPU wait in the same serialized context before reuse. No reuse on timeout, disconnect, missing release, stale/duplicate release or fence-import failure; quarantine/orphan instead. Bounded pools and Damage coalescing avoid blocking the Xserver event loop. V1 proposal uses fresh full-window destinations and defers partial updates/copy-forward. Provider API must distinguish release-fence ordering, pool reuse, terminal destruction and provider quiesce. Detailed lifecycle review used Xserver master `f6df545643f02d04d06ac08f7c81f4da05f7c4cc`; final cross-check refreshed current master to `ee4791f92516141a45b9014aaab7d0eff6afdd3a` and confirmed the relevant Glamor fence helper and modesetting integration unchanged; another refresh to Xserver master `31f845bec4425e1b2048c7763497d752dfe05352` confirmed the same; a further Xserver master refresh to `514357ad2bdb06689f615f87936d60d13cb9a653` again found those integration points unchanged. Spec commit `cb454408f839cd91db312d97ebcf2214e74f98c5`; context commit `0954bbfc05fdfcded0563c47aee0d667a4a707f4`. No Xserver source changes or implementation authorization.


### 2026-11-26 — Composite handoff / provider API follow-up

Xserver master source rechecked at d96a26a11ca6ddc53050f4a96dd0becee9858077. CompositeNameWindowPixmap retains the exact current PixmapPtr; its NameWindowPixmap hook does not replace the named resource. DRI3 provides a useful local Xtrans FD-passing pattern (SetReqFds/ReadFdFromClient and WriteFdToClient) but rejects non-local clients and imports buffers as ordinary pixmaps. It must not become the HDR color contract or a mandatory generic-core dependency.

Spec section 30.12 now proposes a separate versioned extension with BufferReady (no FDs), AcquireBuffer reply (DMA-BUF plane FDs plus producer fence), and ReleaseBuffer request (generation-correlated release fence or explicit NO_USE). The internal provider API is split into async transform submit/collect, export, release-fence import/queue-wait, pool reuse, destruction and quiesce. This is still a design proposal; extension naming, wire layout, compositor authority, XCB FD support, security and failure semantics remain open.

No Xserver code changed; implementation remains unauthorized.

### 2026-11-26 — XCB FD transport verification

X11Libre/mirror.fdo.libxcb master `aa7f3256060451ad65a38feeccf792f44181a4e0`: generated bindings mark FD-bearing replies with `XCB_REQUEST_REPLY_FDS`; libxcb reads the FD count from reply `pad0`, appends descriptors after the reply payload and exposes them through generated `*_reply_fds()` accessors. Request-side `<fd>` fields generate `xcb_send_request_with_fds()`. Received FDs are caller-owned and must be closed before freeing the reply. FD passing is conditional on `HAVE_SENDMSG`; current `XCB_MAX_PASS_FD` is 16 (implementation detail, not wire ABI).

Spec section 30.13 proposes a v1 cap of four DMA-BUF object FDs plus one producer fence, and one release fence or zero for NO_USE. Protocol XML and generated bindings are required; raw XCB requests without the reply-FD flag are unsafe. Client-side FD support is a build prerequisite, not something the server can infer from its own capability query.

Concrete XML schema, runtime transport matrix and compositor interoperability remain open. No Xserver code changes.

### 2026-11-26 — Composite redirect ownership audit

Xserver master `9f1d28b59b6af78033b7f0d0c170935308de046f`: Composite ownership is per-window. Only one manual redirect client is allowed per window; automatic redirect registrations can coexist. `CompositeRedirectSubwindows` creates per-child registrations and tracks future children through a parent resource.

Spec section 30.14 proposes an exclusive HDR compositor claim per screen plus a per-window check that the same client owns manual Composite redirection. Automatic redirection is excluded from v1. PanoramiX/Xinerama mapping and Composite-private helper lifecycle remain open. No Xserver code changes.

### 2026-11-26 — PanoramiX/Xinerama scope

Xserver master `9f1d28b59b6af78033b7f0d0c170935308de046f`: Composite redirects fan out across underlying screens when the PanoramiX path is active; CompositeNameWindowPixmap returns a PanoramiXRes containing one physical pixmap per screen. This differs from RandR multi-output on one ScreenRec.

Spec section 30.15 proposes v1 to support normal ScreenRec/RandR and explicitly report unsupported handoff while Composite PanoramiX/Xinerama is active. Existing Composite fallback remains unchanged. Future aggregate multi-screen generation/lease bundle is open.

### 2026-11-26 — Provisional v1 protocol matrix

Spec section 30.16 drafts the request/reply/event matrix: QueryVersion, QueryCapabilities, AcquireCompositor, ReleaseCompositor, SubscribeWindow, UnsubscribeWindow, AcquireBuffer, ReleaseBuffer; events BufferReady, BufferInvalidated and StreamError. Frame races use explicit extension statuses; X errors remain for malformed IDs/values, access and allocation. The matrix is not a wire ABI; XML schema, field widths, opcodes and generated binding tests remain open.

### 2026-11-26 — XCB protocol-schema mapping

HDR spec section 30.17 now maps the provisional handoff to xcb-proto conventions verified against `gitlab-freedesktop-mirrors/xcbproto:master` (`c70aba5cc6ae87757111dac737fc814b3605f0d4`) and DRI3 XML. It proposes a client-owned CMCONTEXT resource, per-screen epoch, counted FD lists, first-byte reply `nfd`, and XGE for generation-correlated notifications. FD-less transports remain explicitly unsupported. Exact XML/layout, Xtrans validation and generated binding/runtime tests remain open. No implementation or tests were run.

### 2026-11-26 — Xtrans FD transport audit

HDR spec section 30.18 records a critical new blocker from current Xserver master `d439c01fef4c8dcb3a0d05471e3edb0eb00f6f89`: Xtrans FD passing is available only on `local`/`unix` domain sockets; TCP/INET/INET6 explicitly reject FD operations. `SetReqFds()` manages only the remaining expected count; it does not expose the actual per-request ancillary FD count (see the correction below). More importantly, `appendFd()` can fail allocation while `_XSERVTransSocketSendFd()` still returns success; `WriteFdToClient()` can therefore falsely indicate a queued FD. Reliable handoff requires an Xtrans API fix with failure/ownership semantics and transport tests. No code/tests changed.

### 2026-11-26 — Correction: request-scoped ancillary FD accounting

HDR spec section 30.19 corrects the strict-count detail: `ClientRec.req_fds` is only the remaining expected FD counter, not the actual received count. Xtrans currently queues ancillary FDs connection-wide without request-boundary association. Extension-level checking alone cannot reject excess FDs safely. Reliable handoff requires Xtrans to associate ancillary descriptors with exact X request byte boundaries, expose and validate actual per-request counts, reject extras, and propagate both receive- and send-side queue allocation failures. No code/tests changed.

### 2026-11-26 — FD marker offsets / output ordering

HDR spec section 30.20 adds the detailed Xtrans/libxcb framing review. Linux `unix(7)` documents SCM_RIGHTS as a SOCK_STREAM barrier, allowing Xtrans to record the FD marker at `stream_read_offset + recvmsg_bytes - 1` when the client attaches FDs to the first byte of an X request. The server parser must correlate absolute marker offsets with request boundaries because `ReadRequestFromClient()` reads ahead and retains pipelined bytes. The current receive path ignores `MSG_CTRUNC` and does not propagate FD-queue allocation failures.

A second issue was found on both output paths: Xserver `WriteFdToClient()` binds FDs to the next transport write, which may begin with earlier buffered output; libxcb `send_fds()` queues FDs without flushing `out.queue`, and a later `sendmsg()` may start with earlier requests. Require byte-offset/reply-segment-aware FD ordering and regression tests before using the existing helpers for HDR. Linux AF_UNIX is the initial candidate transport; other platforms need verification. No code/XML/tests changed.

### 2026-11-26 — Proposed transport/API contract

HDR spec section 30.21 now proposes an internal transport contract and ordered implementation sequence. Receive-side Xtrans returns FD groups with absolute marker offsets and rejects malformed/truncated ancillary data; DIX validates each marker against the exact first byte and declared FD count of one request. Server output binds FD groups to exact reply byte offsets/segments rather than the next transport write. libxcb must drain preceding buffered requests and atomically stage the FD group with its request. Keep helpers private/additive, preserve legacy DRI3/NVIDIA ABI, and fail closed to SDR. No implementation or tests run.

## 2026-11-26 — SCM_RIGHTS regression PRs and framing correction

- Xserver master remains `d439c01fef4c8dcb3a0d05471e3edb0eb00f6f89`.
- PR [#4230](https://github.com/X11Libre/xserver/pull/4230) adds Linux AF_UNIX framing tests. Its first CI run failed because `test/tests.h` declared `xtrans_fd_test()` twice. Removed the duplicate in commit `6d8ee1bcdf6a261c84690a2a485fdec2be048d84`; exact-head workflow run `45874014274` was pending at the latest refresh, so CI is not yet green.
- PR [#4231](https://github.com/X11Libre/xserver/pull/4231) rejects `MSG_CTRUNC` and closes the FDs delivered in the truncated control buffer. Its build jobs were green except Solaris still running; `Check Signed-Off-By` failed with GitHub `Resource not accessible by integration`. Treat that as a permission/infrastructure failure, not as a verified sign-off failure. PR remains Draft/open.
- The #4230 socketpair test demonstrates `recvmsg()` returning ordinary bytes before an FD-bearing `sendmsg()` together with the entire FD-bearing payload. This disproves the section 30.20 marker formula `read_offset + nbytes - 1`. The HDR design draft now has section 30.22 explicitly superseding that formula; no replacement request-boundary association strategy is approved.
- Further source review confirms `appendFd()` still silently drops descriptors on allocation failure, while receive/send callers ignore the failure. This can leave a partial receive queue or report a send as successful. It is not fixed by #4231 and needs its own scoped regression-tested follow-up.
- No HDR wire protocol/XML or rendering implementation has been started.

### 2026-11-26 — DRI3 FD-passing compatibility review

Owner pointed out that DRI has used FD passing successfully for years. Audited Xserver master d439c01fef4c8dcb3a0d05471e3edb0eb00f6f89: DRI3 uses the established connection-wide FIFO. Xtrans appends descriptors received through recvmsg(); DRI3 declares expected counts via SetReqFds(N) and consumes descriptors in order via ReadFdFromClient(). Replies queue FDs via WriteFdToClient() immediately before X_SEND_REPLY_SIMPLE(), and Xtrans attaches them to the next socket write.

Conclusion: lack of exact byte offsets in a batched recvmsg() does not itself break the established DRI3 flow. HDR should preserve the FIFO contract and should not require byte-offset tracking or a replacement transport API without a demonstrated need. Section 30.23 of the HDR spec records this corrected direction.

Remaining hardening: SetReqFds() logs mismatches but overwrites the expected counter; appendFd() can fail allocation while callers still report success; receive queue has no group boundaries; test output ordering when an earlier write remains buffered after EAGAIN before a later FD-bearing reply. Plan is additive compatibility-preserving fixes and focused tests, not replacing the DRI3 path. No Xserver implementation/XML changed.


## 2026-11-26 — Xtrans FD queue allocation failure follow-up

Draft Xserver PR [#4232](https://github.com/X11Libre/xserver/pull/4232), branch `fix/xtrans-fd-queue-allocation-failure`, head `401caa60a35ccb18ce7072528b34b754f7d6d031`:

- `appendFd()` propagates `ENOMEM` and does not close the caller's FD on failed queueing; send path propagates the failure.
- Receive-side append failure closes all descriptors in the failed/remaining ancillary group and the already queued receive FIFO, then returns an error.
- Added Linux tests through actual Xtrans local transport APIs with linker-wrapped `malloc()` failure injection.
- Initial workflow 45881893934 failed compilation because `__wrap_malloc` lacked a prior prototype under `-Wmissing-prototypes`; added the prototype in commit `f8d278e9711f3a3750d802cb5e5a7855ae514d9f`. A fresh exact-head run had not appeared at last check. No local build/test claimed; draft pending fresh CI and review.
- Shares `os/Xtranssock.c` with PR #4231, so coordinate rebase/merge ordering.


## 2026-11-26 — Signed-Off-By workflow permission follow-up

- Diagnosed `Resource not accessible by integration` in the sign-off action: action logs enumerate commits, then fail while trying to post a comment for unsigned commits. The action source uses the Pull Requests API and `issues.createComment()`.
- Draft Xserver PR [#4233](https://github.com/X11Libre/xserver/pull/4233), branch `ci/fix-signoff-action-permissions`, adds narrowly scoped `pull-requests: write` to the sign-off job only.
- Workflow run 45882365691 queued at last check. The PR itself is unsigned; expected action behavior after permission fix is to report DCO, not silently pass.
- #4230–#4232 must be rerun after #4233 and all commits must carry valid Signed-off-by trailers before merge.


## 2026-11-26 — DCO sign-off and replacement PRs

Owner explicitly authorized DCO sign-off in their name. Verified existing Xserver signed commits and used:

`Signed-off-by: Enrico Weigelt, metux IT consult <info@metux.net>`

To avoid rewriting existing branches/force-pushing, created one-commit replacements with identical Git trees and the same master parent:

- #4230 → [#4234](https://github.com/X11Libre/xserver/pull/4234), head `ec8356ff43d5f5674983238bbb7cb7d62ff71a9a`
- #4231 → [#4235](https://github.com/X11Libre/xserver/pull/4235), head `6499dc22620a0378c76a083a7c0afa028060eead`
- #4232 → [#4236](https://github.com/X11Libre/xserver/pull/4236), head `e73f28888e3c6070ed6d208af5bd3eb557f29ae9`
- #4233 → [#4237](https://github.com/X11Libre/xserver/pull/4237), head `d9bdcdd8a505dfc7586ed057993211232dc070c7`

Each replacement has exactly one commit, API-verified author/committer `Enrico Weigelt <info@metux.net>`, and the DCO trailer. CI was queued on all exact heads. Original PRs remain open until replacement CI and DCO checks pass. No local build/test claimed.


### 2026-11-26 — Xtrans PR branch consolidation and Alpine linker fix

- Per owner instruction, consolidated the signed-off work on the original PRs #4230–#4233; no replacement PRs remain active. Each original branch is now a single commit based on Xserver master `d439c01fef4c8dcb3a0d05471e3edb0eb00f6f89` and carries the authorized DCO trailer.
- Current heads / exact-head CI runs:
  - #4230 `8aaa71ad6d424e987ab5880fd97c6fd86b30f2f6` / `45888660431` queued.
  - #4231 `dfe2e77d4c832ac00820fd2f231b85c024d0eede` / `45888664565` queued.
  - #4232 `c50bd2aa6b4f12f9fd153613f78a5b037c7cbac9` / `45888560671` queued.
  - #4233 `2c65e302c47d6edddb8296cd1321e7354f1f851a` / `45888669984` queued.
- Closed #4234–#4237 as superseded, not merged. The original PRs #4230–#4233 remain open.
- Fixed the Alpine/musl link failure seen on the prior #4236 exact head by marking the malloc wrapper default-visible. Previous failure was: hidden `__wrap_malloc` referenced by DSO. The fix is pending exact-head CI; do not claim validated yet.
- The Signed-Off-By job passed on former replacement #4234 run `45883291726`. Current original PR exact-head runs are queued.
- No Xserver local build/test was run; no PR merged. Continue to inspect full CI matrices and review all diffs before recommending merge.


### 2026-11-26 — Deep review, live MSG_CTRUNC test, and stacked PR ordering

- Exact-head CI for #4230 (`45888660431`) and #4233 (`45888669984`) completed with 18 successful jobs, 7 workflow-skipped jobs, and no failures. Their DCO checks passed. #4230's Ubuntu `xserver:unit` passed. Previous exact heads of #4231 (`45888664565`) and #4232 (`45888560671`) also had 18 successful / 7 skipped jobs, including Alpine and DCO, but those heads have since been extended.
- Added live Xtrans MSG_CTRUNC regression to #4231. It sends 129 FDs through a real local Xtrans connection against the 128-FD receive control buffer, expects `EMSGSIZE`, and checks that no received FD remains open. Current head `d515dc6959b28fa2f2c25c8259c48e80bfc54a79`; exact-head run `45904081384` is in progress, with DCO already successful.
- Moved #4232's allocation-test registration/prototype after `xkb_test` to avoid same-gap conflicts with #4230. #4231 registers its test after `ddc_tests`; #4230 remains after `xfree86_test`. Meson source insertions also have distinct anchors.
- Stacked #4232 on #4231: base branch `fix/xtrans-reject-truncated-fd-groups` at `d515dc6...`; current head `f3c106b9960d20cbe31ef4c854e0f5b9d6f47ca7`. The #4232 diff now contains only the allocation-failure delta. Exact-head run `45904354611` is pending.
- #4230 current head `8aaa71ad6d424e987ab5880fd97c6fd86b30f2f6`; #4233 current head `2c65e302c47d6edddb8296cd1321e7354f1f851a`. All remain open/draft; no merge.
- Note seven skipped jobs are Arch, macOS, Cygwin, image/dependency and release jobs: report only that all executed jobs are green, not that every possible platform was exercised. GitHub API `verification=false/unsigned` means no GPG signature; it is separate from the DCO trailer, which the check action recognizes.

### Follow-up — FreeBSD portability fix (2026-11-26)

- Run 45904081384 for #4231 failed on FreeBSD while compiling test/xtrans-fd-trunc.c: NULL was undeclared because stddef.h was inside the Linux-only guard. Moved stddef.h to the unconditional includes.
- Current #4231 head: 60a22b75864952817bd1589deac81571574ce5a7; exact-head run 45904923410 pending.
- Rebased stacked #4232 onto that corrected #4231 head. Current #4232 head: b8febd859ebffb83e5a1964d411eaafb92bf008b; exact-head run 45904977771 pending.
- Earlier heads are superseded. No PR merged; do not treat prior green runs as current-head validation.

### Follow-up — allocation-test portability and pending CI

- Moved stddef.h in test/xtrans-fd-alloc.c outside LDWRAP_TESTS, because its NULL sentinel is unconditional even when linker-wrap tests are disabled.
- Current #4232 head: e82644d98e58ade396950172ddbd341463ac6f16; parent #4231 current head 60a22b75864952817bd1589deac81571574ce5a7; CI run 45905193967 pending.
- #4231 current head remains 60a22b75864952817bd1589deac81571574ce5a7; CI run 45904923410 pending.
- Earlier #4232 head b8febd... is superseded. No PR merged.

### Stacking cleanup — #4232 allocation-only diff

- Made test/xtrans-fd-trunc.c byte-identical between #4231 base and #4232 head; the #4232 patch now lists exactly five allocation-only files.
- Current #4232 head 2429f7f00860501602a86452f59b037895a0c925, parent #4231 head 60a22b75864952817bd1589deac81571574ce5a7; run 45905471008 pending.
- #4231 head 60a22b75864952817bd1589deac81571574ce5a7; run 45904923410 pending.
- No merges. After #4231 merges, rebase/retarget #4232 to updated master and rerun CI.


## 2026-11-27 — Current HDR transport refresh

This refresh supersedes the older marker-offset proposal in the 2026-11-26 notes. The normative correction is in wormhole-0 master section 30.22; the current request-bounded candidate is in section 30.27. Do not use the former formula based on recvmsg() byte count.

### Receive-side candidate

A standalone Linux AF_UNIX/SOCK_STREAM experiment and the registered Xserver regression in PR #4230 show that a receiver positioned at an X request boundary can read only the current header (including a partial header) and receive the FD group with the first header read. Later header/body reads do not receive that group. Candidate HDR-only strategy: after a compositor-acquisition round-trip barrier, disable request read-ahead for negotiated HDR clients, expose per-read FD counts from Xtrans, parse the request length including BIG-REQUESTS, then read exactly the remaining request body. Validate the declared FD count against the group received during the header read; reject FDs arriving during body reads. Keep the existing FIFO ownership/consumption model and leave legacy DRI3 input behavior unchanged. This is not implemented in the Xserver parser or libxcb and is not an approved wire ABI.

### Output-side blocker

The output path remains unresolved. WriteFdToClient queues FDs for the next transport write; FlushClient may begin with earlier buffered bytes after EAGAIN, so a later FD-bearing reply could attach to an older event/reply. Candidate HDR-only mitigation: flush all prior output before queueing an FD group, ensure reply-buffer capacity before queueing, then queue the group and write the reply; if prior output remains pending after EAGAIN, return a retryable BUSY/WOULD_BLOCK result without queueing the FD. This needs a dedicated DIX-level backpressure regression and proof that partial writes preserve the reply/FD association. Do not change the legacy DRI3 WriteFdToClient path until that test exists.

### Current Xserver transport PRs

- [#4230](https://github.com/X11Libre/xserver/pull/4230) head 4fb7f5e73eb9944797ab9b9e5ae50d6a2fbc37f6: Linux AF_UNIX framing, multi-marker, MSG_CTRUNC and request-bounded partial-header tests. The bounded-read test is registered. Exact-head runs 45915160161 and 45915153363 are pending.
- [#4231](https://github.com/X11Libre/xserver/pull/4231) head fd0443f1d0e79fcaf2eb3f30b43963e5edbc5a32: reject MSG_CTRUNC, close all received FDs and fail with EMSGSIZE. Both exact-head runs are green: 45912011180 (20 passed, 5 skipped) and 45912016553 (18 passed, 7 skipped); DCO passed.
- [#4232](https://github.com/X11Libre/xserver/pull/4232) head b0174238f714c077574d8948e1382bebc74354e5, stacked on #4231: propagate allocation errors, add atomic SendFds/WriteFdsToClient group queueing, and fix DRI3 BuffersFromPixmap so multi-plane FDs are queued all-or-nothing. Exact-head runs 45915525711 and 45915520647 are queued. An intermediate head had a SendFd/SendFds dispatch mismatch; current head fixes it.
- All three remain Draft, unreviewed and unmerged. #4232 must be retargeted/rebased after #4231 merges. No local Xserver build/test has been run.

### Scope boundary

This HDR session has not implemented the HDR wire protocol/XML, request parser, libxcb changes, output metadata, or rendering pipeline. The work above is transport regression/hardening plus a candidate framing strategy. Keep the already-approved linear BT.2020/D65 working space, FP16 premultiplied compositor handoff and 203 cd/m² neutral reference white separate from these still-open transport and ABI decisions.


## 2026-11-27 — Per-read FD group validation

The request-bounded candidate now has an additional required validation point: a flat FIFO cannot distinguish two separate SCM_RIGHTS groups if they arrive on successive partial reads of one request header. Xserver PR #4232 now adds the private _XSERVTransGetLastReadFdCount() getter, reset on every read, plus a live Xtrans regression observing counts 0, 2, 1, 0 across an ordinary request, a two-FD first header group, a second one-FD partial-header group, and the body. The Xserver parser must use this signal: accept a nonzero group only on the first read at the request boundary; reject any later nonzero read during the rest of the header or body. The new Xserver #4230 regression sends two one-FD groups on successive two-byte header fragments and verifies that the kernel delivers them on separate recvmsg() calls. Current #4230 head is 51b4086038600c50463fd76f530dc48d718a0a88, with exact-head CI runs 45915160161 and 45915153363 pending.


## 2026-11-27 — Xtrans per-read FD count API

Xserver PR #4232 now includes _XSERVTransGetLastReadFdCount(), which reports the number of descriptors received during the immediately preceding Xtrans read. The count resets on every read and is cleared on read failure. Its live test verifies 0, 2, 1, 0 for an ordinary request, a two-FD group on the first partial header read, a second one-FD group on a later partial header read, and the body. This supplies the transport-side signal required by the HDR request-bounded candidate; the Xserver request parser still needs to use it and disable read-ahead for negotiated HDR clients.


## 2026-11-27 — ReadRequestFromClient parser integration point

Current Xserver master os/io.c:ReadRequestFromClient() computes needed and gotnow for the xReq header, BIG-REQUESTS extension header and full request, but its transport read currently asks for all remaining input-buffer capacity (oci->size - oci->bufcnt), which permits read-ahead into subsequent requests.

For negotiated HDR clients only, cap that read length to needed - gotnow. Track request_read_index and accumulated request_fd_count in private ConnectionInput/OsComm state: after each positive read, call _XSERVTransGetLastReadFdCount(); accept a nonzero count only on the first positive read of the request, accumulate it, and reject any later nonzero read (including later partial header fragments or the body). After the full request is assembled, expose the accumulated count to the HDR handler for comparison with the request-declared count before it consumes the FIFO.

Enable this mode only after the compositor-acquisition round-trip barrier, and reject enabling it if bytes beyond the negotiation request are already buffered. EAGAIN/zero-byte reads do not advance request_read_index. Existing BIG-REQUESTS parsing remains authoritative. Legacy DRI3 and ordinary clients keep the existing read-ahead behavior. This is the next parser implementation task; it is not included in the current Xserver PRs.


## 2026-11-27 — Current implementation checkpoint

- Xserver master: `d439c01fef4c8dcb3a0d05471e3edb0eb00f6f89`.
- Xtrans hardening/test PRs #4230–#4233 have green exact-head CI on all executed jobs; all remain Draft/open/unmerged. #4232 is stacked on #4231.
- Draft PR [#4240](https://github.com/X11Libre/xserver/pull/4240) proposes milestone 0 only: length-aware EDID parsing, bounds-safe extension walkers, complete-extension validation, normal modesetting/full-DDC integration and malformed/truncated-input tests. Head: `ff89fbe00aa56b3c80ef3382f83b17f40fff4f50`.
- #4240 exact-head CI run `45994542211` is queued. No local build/test was run.
- No HDR output signaling, client protocol/XML, request parser or rendering behavior is implemented. No PR has been merged.
