---
slug: xlibre/nvidia-abi-living-record
title: "NVIDIA driver ABI — living record of empirical findings"
order: 200
owner: "Excelsior"
---

## NVIDIA driver ABI — living record of empirical findings

**Living document.** What the proprietary NVIDIA X driver actually consumes from the X server's
driver ABI. Used during PR review (see `bot-review` skill, rule 3) to decide whether a change
breaks an installed — possibly *old* — nvidia blob, which **cannot be recompiled**. Maintained
by **both humans and agents**: append confirmed findings, prune false positives, bump the
"versions checked" list as new drivers are tested.

## Why this matters

The nvidia `nvidia_drv.so` (and its GLX module) is a binary blob linked against the server's
driver ABI. We must *preserve* that ABI — versioning a break is not an option, because old blobs
stay in the field. A PR that changes a public struct layout, or removes/renames an `_X_EXPORT`
symbol the blob depends on, breaks it at load or run time.

## Two ways the blob reaches a server symbol — check BOTH

1. **Link-time import** — an undefined dynamic symbol, visible via `nm -D --undefined-only`.
2. **Runtime lookup by name** — `dlsym()` / the server's `LoaderSymbol()`, where the symbol name
   exists **only as a string literal** in the blob and is **invisible to `nm`**. Confirmed: the
   blobs import `LoaderSymbol` and resolve many `xf86*`/`mi*` names this way.

`scripts/nvidia-abi-check` checks both (imports ∪ string literals). A plain `nm` dump (the old
`scripts/nvidia-undefined-symbols`) misses the runtime-lookup half — that gap already produced a
wrong "safe" verdict (#2070, `xf86CursorScreenKeyRec`).

## How to (re)generate / update this doc

```sh
scripts/fetch-nvidia-drivers                       # or: fetch-all-nvidia-drivers --per-branch
scripts/nvidia-abi-check SymA SymB ...             # classify specific symbols
scripts/nvidia-undefined-symbols | sort -u         # raw import dump
```

To check whether a specific change is safe, run the unexported/changed names through
`scripts/nvidia-abi-check`; a hit in either column means "keep it".

## Versions checked

`390.157`, `470.256.02`, `550.142`, `570.133.07` (legacy 390 → current 570). The findings below
hold across **all** of these unless noted. **TODO:** widen with
`scripts/fetch-all-nvidia-drivers --per-branch` (77 branches) for exhaustive coverage.

## Dependency surface (empirical, from the versions above)

Server-ABI symbols the blob references (excluding libc/system): **~335 hard imports + ~40
runtime-lookups**. By subsystem (hard imports): `xf86*` 76, `mi*` 49, `RR*` 33, `dix*` 11,
`miOverlay*` 5 (←!), `Picture*` 3, `Composite*` 2, `Loader*` 1. Plus public structs read at
fixed offsets (`ScrnInfoRec`, `ScreenRec`, …) — **do not reorder/insert fields except at the tail**.

### Runtime-lookup-only symbols (resolved by name — `nm` does NOT see these)

These are the dangerous, easy-to-miss ones. **Must stay `_X_EXPORT`.**

- **Loader/ABI:** `LoaderGetABIVersion`, `LoaderShouldIgnoreABI`
- **xf86:** `xf86CursorScreenKeyRec`, `xf86AddInputHandler`, `xf86RemoveInputHandler`,
  `xf86EnableInputHandler`, `xf86DisableInputHandler`, `xf86GPUScreens`, `xf86NumGPUScreens`,
  `xf86PciAccInfo`, `xf86UpdateDesktopDimensions`
- **RENDER:** `PictureScreenPrivateKey`, `PictureScreenPrivateKeyRec`, `PictureScreenPrivateIndex`
- **mi:** `miDisableCompositeWrapper`, `miEmptyBox`, `miEmptyData`,
  `miZeroLineScreenKey`, `miZeroLineScreenKeyRec`
- **RANDR:** `RRCrtcType`, `RRModeType`, `RROutputType`
- **Present:** `present_event_notify`, `present_screen_init`
- **Shadow:** `shadowAdd`, `shadowRemove`, `shadowSetup`
- **GLX (needs confirmation — may be nvidia's own module symbols):** `glxModuleData`, `glxServer`
- _Auto-extracted noise to ignore (binary fragments, not real symbols): `fbconfigH/I`, `miAqW`,
  `RR2G`, `RRK3y`, `Xve9`, `Xvgh`, `XvMx6N`, `present_H`._

## Confirmed do-not-break rules (from PR review)

| Symbol / struct | Rule | Evidence |
|---|---|---|
| `miInitOverlay`, `miOverlayComputeCompositeClip`, `miOverlayCollectUnderlayRegions`, `miOverlayCopyUnderlay`, `miOverlayGetPrivateClips`, `miOverlaySetRootClip` | keep exported — **link-imported by all of 390/470/550/570** | #1786 (delete) breaks all; #1787 (dummy-export) is safe |
| `xf86CursorScreenKeyRec` | keep `_X_EXPORT` — **runtime-looked-up by all 4** | #2070 |
| `monitorResolution` | keep `_X_EXPORT` — **runtime-looked-up by all 4** | (still exported in `include/globals.h`; watch it) |
| `PictureMatchVisual`, `PictureFindFilter`, `PictureMatchFilter`, `SetPictureFilter` | keep exported | #1469 keeps them; drivers use them |
| `ScreenRec` / `ScrnInfoRec` etc. | append new fields only at the **tail** (past the PRIVATE marker) | #2662 (tail-append) was safe |

### Confirmed *not* used (safe to remove, per these versions)

- Server-side **XvMC** entry points (`xf86XvMCScreenInit`, `xf86XvMCCreateAdaptorRec`,
  `xf86XvMCRegisterDRInfo`, `XvMCScreenInit`) — referenced by none of the 4 (nvidia's XvMC is
  client-side). Re-confirm if testing a driver branch known to register an XvMC adaptor. (#808)
- The ~23 RENDER funcs unexported by #1469 (gradient creators, `Composite*`, `AddTraps`, …) —
  unreferenced by all 4.
- DIX resource-type bookkeeping globals `lastResourceType` and `TypeMask` unexported by #1388 —
  neither imported nor looked up by name in any of the 4. Drivers allocate resource types via the
  exported `CreateNewResourceType()`, not by touching these internals. Safe to unexport.
- DIX internal region helpers `InitRegions`, `RegionRectAlloc`, `RegionIsValid`, `RegionPrint`
  unexported by #1389 (moved to a private `dix/region_priv.h`) — neither imported nor looked up by
  name in any of the 4. `InitRegions` is a one-time DIX init (`dix/main.c`); `RegionRectAlloc` is an
  internal pixman-region grow helper; `RegionIsValid`/`RegionPrint` are `DEBUG`-only. Drivers use
  the exported `Region*` API (`RegionCreate`/`RegionInit`/…), not these. Safe to unexport.

### Batch sweep of open `unexport` PRs (2026-06-25, vs 390.157 / 470.256.02 / 550.142 / 570.133.07)

All open `unexport`-labelled PRs were checked (link-import ∪ runtime-lookup). The label
`needs-nvidia-verification` was added to each to gate the merge on maintainer sign-off. **Net**
unexported symbols only (a symbol re-added with `_X_EXPORT` in the same diff stays exported and was
excluded). All of the below are **unreferenced by all 4** → safe:

- #1914 `xf86PlatformDeviceCheckBusID`; #1481 `LogHdrMessageVerb`; #1467 `defaultColorVisualClass`;
  #1387 `DontPropagateMasks`; #1358 `defaultFontPath`; #1355 `XNFvasprintf`.
- #1487 — only `PixmapScreenInit` is net-unexported (the other `Pixmap*` in the diff keep
  `_X_EXPORT`).
- #1383 `CloseDownExtensions`, `EnableDisableExtensionError`, `GetExtensionEntry`, `InitExtensions`,
  `NotImplemented`.
- #1469 (RENDER) — the 23 net-unexported funcs (gradient creators, `Composite*`, `AddTraps`,
  `PictureInit`, filter setup, transform converters) are all unreferenced. **Caveat / corrects an
  earlier note:** `PictureFindFilter`, `PictureMatchVisual`, `SetPictureFilter` ARE link-imported by
  all 4 blobs — but #1469 **keeps them `_X_EXPORT`** (re-added in the same diff), so the PR is safe.
  Do NOT unexport those three.

## Residual blind spot

The string scan only catches names that appear **verbatim**. A driver that builds a symbol name
by runtime string concatenation would evade detection. None observed so far, but keep it in mind.

## NVIDIA GL/GLX protocol surface (how the closed stack plugs in)

Reverse-engineered from `nvidia_drv.so`, `libglx.so.390.157`, `libglxserver_nvidia.so.{470,550,570}`
(strings/symbols). NVIDIA is closed-source, so wire layouts of the private opcodes are **not**
public.

- **Standard GLX** — public X extension; full GLX 1.4. Carries context/drawable/fbconfig *setup*
  (and, for *indirect* rendering only, the GL stream). Direct rendering does **not** flow over GLX.
- **`NV-GLX`** — NVIDIA **private X extension** (major opcode ~137). Coordination, not bulk data:
  `pixmap lock`, `pbuffer` (it creates X **resource types** for these), `framebuffer capture`,
  `modeset permission`, `sideband client notification` (the bit `glWaitSync`/GL-CL interop hits).
- **`NV-CONTROL`** — the `nvidia-settings` extension (this half *is* open: `libXNVCtrl`).
- **Real data path is NOT DRI.** Clients `ioctl()` NVIDIA's own kernel nodes — `/dev/nvidiactl`,
  `/dev/nvidia%d`, `/dev/nvidia-modeset`, `/dev/nvidia-uvm` (the RM API) — allocating **DMA push
  buffers** + **CE channels**, submitting work, and fencing via **hardware semaphores**. Buffer
  objects and fencing live here, parallel to X/DRM.
- **DRI2/Present, narrowly:** all versions link `DRI2ScreenInit`/`libdrm`; 570 adds Present
  (`present_screen_init`). Used for X-side buffer handoff (`texture_from_pixmap`, redirected
  windows, swap/present timing) — **not** the rendering transport. **No DRI3** in any version.
- **Server-module model split:** **390** ships `libglx.so` that *replaces* the server's own GLX
  module; **470+** ship `libglxserver_nvidia.so`, a **GLXVND vendor module** under the server's
  `GLX_EXT_libglvnd` dispatch. Both register `NV-GLX`/`NV-CONTROL` via server symbols resolved by
  *runtime lookup*: `AddExtension`, `MakeAtom`, `CreateNewResourceType`, `dixRegisterPrivateKey`
  (→ these belong on the keep-exported watch-list above).

## Direction: replace the X-side blob with an EGL-backed open driver

**Goal:** drop the closed `nvidia_drv.so` + `libglxserver_nvidia.so` and drive the GPU from an
**open** X driver that sits on NVIDIA's generic userspace **EGL** stack — the same path Wayland
compositors and single-screen EGL apps use — instead of NVIDIA's X-specific blobs.

**Why this matters for *this* doc:** the entire ABI-preservation regime above exists to protect a
consumer that *cannot be recompiled* (the blob). **Replacing it with an open, recompilable driver
lifts that constraint** — the unexport/struct-layout rules stop being load-bearing for the NVIDIA
path once the blob is gone. So this doc is the map of what must hold *until* the replacement lands,
and the checklist of what the open driver must re-provide. (See architecture notes in
`NVIDIA-OPEN-DDX.md`.)

