---
slug: alloc-fail-uaf-sweep-m0126-phase1-dix-os
title: "Alloc-fail/UAF security sweep (praetor directive m0126) — Phase 1 findings"
category: parked
noted_by: "Farragut (m0126 directive) / Intrepid (dix/+os/) / Constellation (Xext+mi+miext, hw/xfree86, intel+amdgpu, nouveau+vmware+qxl, input drivers) / Pegasus (cross-check dix/os/Xext/mi + hw/xfree86 rest/glamor/composite + xf86-video-ati/freedreno/mga/savage/siliconmotion/nv/vmware/qxl-extra/~32 sampled legacy drivers + xf86-input-evdev/elographics/joystick/keyboard/mouse/vmmouse/void)"
since: "2026-07-07"
---

Praetor directive relayed by Farragut (m0126): sweep the xlibre source tree + drivers for
allocation-failure-handling gaps and use-after-free. **Phase 1 only** — findings collected here,
no fixes yet. Phase 2 (fixes/PRs, likely one ship per finding-cluster/component) follows once
enough of the tree is covered — coordinate via agent-bus before starting a fix so two ships don't
duplicate.

**Scope covered so far** (all against `_WORK_/xserver-master/sources/xlibre/`, master branch, via
research agents — read-only, no fixes):
- `dix/` and `os/` — Intrepid, 2026-07-07.
- `Xext/`, `mi/`, `miext/` — Constellation, 2026-07-07.
- `hw/xfree86/common/`, `hw/xfree86/os-support/` — Constellation, 2026-07-07.
- `xf86-video-intel`, `xf86-video-amdgpu` (xf86-video-ati has a fully separate `src/` tree, not
  scanned) — Constellation, 2026-07-07.
- `xf86-video-nouveau`, `xf86-video-vmware`, `xf86-video-qxl` — Constellation, 2026-07-07.
- `xf86-input-libinput`, `xf86-input-wacom`, `xf86-input-synaptics` — Constellation, 2026-07-07.
- **Independent re-check of `dix/`, `os/`, `include/`, `Xext/`, `mi/` — Pegasus, 2026-07-07.**
  Ran blind (before seeing Intrepid/Constellation's results) via a separate research agent;
  cross-referenced afterward. Most findings landed on the exact same bugs (see "Cross-confirmed"
  below) — good independent corroboration. A few findings **contradict** Constellation's "checked,
  nothing solid found" verdict for `Xext/security/`, `Xext/xselinux/`, `Xext/xv/`, and
  `mi/miwideline.c` — flagged explicitly below for a tie-breaker look before Phase 2 skips them.
- **`hw/xfree86/common/` (parser + remaining common/ files not covered above), `hw/xfree86/parser/`,
  `Xext/composite/`, `glamor/`, `exa/`, `fb/`, `randr/render` (inside `Xext/`) — Pegasus, 2026-07-07.**
- **`xf86-video-ati` (own tree — genuinely new, nobody had scanned it), `xf86-video-freedreno`,
  `xf86-video-mga`, `xf86-video-savage`, `xf86-video-siliconmotion`, `xf86-video-nv`,
  extra `xf86-video-vmware`/`xf86-video-qxl` files beyond what Constellation covered, plus a
  sampling pass (varying depth) across all ~32 other `xf86-video-*` legacy drivers — Pegasus,
  2026-07-07.**
- **`xf86-input-evdev`, `xf86-input-elographics`, `xf86-input-joystick`, `xf86-input-keyboard`,
  `xf86-input-mouse`, `xf86-input-vmmouse`, `xf86-input-void` — Pegasus, 2026-07-07.**

**Still unscanned** — free ships should pick one and claim it here (or via agent-bus) before
starting, to avoid duplicate sweeps: `xkb-config`/keyboard config data paths outside
`Xext/xkeyboard/` already covered, and full line-by-line depth on the ~32 sampled-only legacy
video drivers (only grep+spot-read depth, not exhaustive — see Pegasus's per-repo notes for which
were sampled vs. skipped). `xf86-video-intel`'s shader/codegen files and most EXA accel backends,
and `xf86-video-ati`'s shader/codegen + most EXA backends, were grep-only, not read function-by-
function — worth a deeper pass if time allows.

## Findings

1. **`dix/getevents.c:384-387` (alloc-fail gap → NULL-pointer memcpy), confidence high.**
   `AllocateMotionHistory()`'s `calloc` failure path only logs via `ErrorF` — it doesn't reset
   `pDev->valuator->numMotionEvents` to 0 and the function is `void` (caller,
   `InitValuatorClassDeviceStruct` in `dix/devices.c:1362`, checks nothing). Later,
   `updateMotionHistory()` (`dix/getevents.c:534`) only guards on `numMotionEvents != 0` (still
   true), so it proceeds to `memcpy()` through the NULL `pDev->valuator->motion`. Triggerable by
   plain memory pressure at input-device-init time (e.g. hotplugging a device under OOM) — a
   legitimate low-memory DoS. **Cross-confirmed independently by Pegasus's blind re-check.**

2. **`dix/ptrveloc.c:435` (alloc-fail gap, no NULL check at all), confidence high (as a code
   defect); low real-world trigger likelihood.** `InitTrackers()`'s `calloc(ntracker, ...)` for
   `vel->tracker` has zero failure handling; later indexed/written unconditionally via the
   `TRACKER()` macro. All current call sites pass a fixed small `ntracker = 16`
   (`dix/ptrveloc.c:113`), so it needs OOM at a very small allocation to actually trigger, but the
   code path itself has no defense at all. **Cross-confirmed independently by Pegasus's blind
   re-check.**

3. **`dix/registry.c:73-80` + `:337-361` (self-overwriting `realloc()` → NULL-deref in its own
   cleanup path), confidence high (Constellation, cross-checked against Intrepid's list — net new,
   not a duplicate of items 1-2).** `double_size()`'s `*ptr = realloc(*ptr, n);` overwrites the only
   pointer to the existing buffer directly; on failure this leaks the old block and leaves the
   caller's size counter (`nmajor`/`nevent`/`nerror`) out of sync with the now-NULL data pointer. It
   then calls `dixResetRegistry()` → `dixFreeRegistry()`, which loops `while (nmajor--) { ...
   free(requests[nmajor][...]); ... }` using the **still-nonzero** counter against the just-NULLed
   array — dereferencing near-NULL memory before ever reaching `free()`. Trigger:
   `RegisterRequestName()` (called at server startup while building the request/extension registry
   from `protocol.txt`) hits OOM on a growth call once the tables have already grown past the first
   size class (`nmajor > 0`, roughly after the first ~16 extensions) — only compiled in on
   SELinux/XSecurity/dtrace/namespace-enabled builds (`X_REGISTRY_REQUEST`), but on those builds
   it's on the normal startup path. **Cross-confirmed independently by Pegasus's blind re-check.**

4. **`os/client.c:290-304` (alloc-fail gap, platform-specific), confidence medium.**
   `DetermineClientCmd()`'s `__DragonFly__`/`__FreeBSD__` sysctl branch: `calloc(1, len)` for
   `procargs` is used immediately as the sysctl output buffer and later `strlen()`/`strdup()`'d,
   with no NULL check between allocation and first use. Whether a NULL `procargs` actually reaches
   `strlen`/`strdup` depends on whether the kernel's own `sysctl()` call already faults on a NULL
   buffer pointer first (likely, but not guaranteed on every implementation) — needs OOM either way.
   **Cross-confirmed independently by Pegasus's blind re-check, which additionally notes: BSD
   `sysctl()` with a non-NULL `oldp` returning 0 is a valid *successful* call, so the existing
   `!= 0` error check does NOT catch a NULL `procargs` reaching `sysctl()` — strengthens confidence
   to high.**

5. **`os/log.c:386-388` (freed-but-not-NULLed globals → latent UAF/double-free), confidence medium
   on the defect, but currently NOT reachable/live.** `LogSetDisplay()` frees
   `saved_log_fname`/`saved_log_backup` (module-level globals) without resetting them to NULL. If
   the function were ever called a second time, the top-of-function reuse of those globals would
   read freed memory and then double-free them. Traced the call graph: exactly one call site
   (`os/connection.c:273`, inside `CreateWellKnownSockets()`), itself called exactly once per
   process (`dix/main.c:157`) — so not live under the current code, just a defensive gap that would
   bite the moment anything calls `LogSetDisplay()` twice (e.g. a future re-init/reload feature).

### Noted in passing, not one of the two requested bug classes (informational only)

- **`os/xdmauth.c:461`, `XdmRemoveCookie()`** has a linked-list unlink bug unrelated to
  alloc-fail/UAF: it does `xdmAuth = auth->next` unconditionally instead of tracking a `prev`
  pointer like the equivalent `MitRemoveCookie` does, so removing a non-head entry leaves the list
  head unchanged and orphans/leaks every entry before the removed one. Worth a separate look, not
  bundled into this security sweep's scope.

## Findings: `Xext/` + `mi/` + `miext/` (Constellation)

**Phase 2 progress (Constellation, m0130 assignment — Xext/mi/miext cluster):** the 3
deterministic/no-OOM items Enterprise flagged as highest priority (m0130) are fixed, built+tested
(full `ninja` build + `meson test`, all 45 tests pass, including `pyxtest-test_present.py` and
`pyxtest-test_render.py`) and each submitted as its own PR against `master`:
- Item 1 (present_notify UAF) → [PR #3265](https://github.com/X11Libre/xserver/pull/3265)
- Item 2 (dri2 OOB write) → [PR #3266](https://github.com/X11Libre/xserver/pull/3266)
- Item 3 (render.c glyph leak) → [PR #3267](https://github.com/X11Libre/xserver/pull/3267) — the
  fix (`FreeGlyph()` instead of a raw `refcnt--`+`free()`) also covers Pegasus's multi-screen angle
  noted below (`FreeGlyphPicture()` iterates all screens via `DIX_FOR_EACH_SCREEN`, so a partial
  multi-GPU realization is cleaned up the same way) — one PR, not two, per Pegasus's own suggestion.
- Item 4 (Xi `AddExtensionClient` double-free) → [PR #3271](https://github.com/X11Libre/xserver/pull/3271)
- Item 9 (randr `AddResource`-OOM leaks, 5 files: `rrlease.c`/`rrmode.c`/`rrcrtc.c`/`rroutput.c`/
  `rrprovider.c`) → [PR #3273](https://github.com/X11Libre/xserver/pull/3273), one bundled PR since
  it's the same missing-cleanup shape repeated across the subsystem.

None of these touch `hw/xfree86`/driver code, so the AGENTS.md "HW-Reviewer vor Merge" rule (m0130)
doesn't apply — normal review process. **5 of 11 cluster items now have PRs out.** Still open:
item 6 (`DeepCopyPointerClasses` NULL deref), items 7+8 (`xkeyboard` reallocarray/leak, 2 sites —
plausible bundle), item 5 (GLX indirect stale-size, needs indirect-GLX test setup, harder to
verify), item 10 (`mi/midispcur.c` dangling devPrivates), item 11 (`miext/rootless` dangling screen
pixmap, Xquartz-only backend). Picking those up next unless reassigned.

1. **`Xext/present/present_notify.c:41-43` + `present_screen.c:117-124` + `present_vblank.c:284-285`
   — UAF, high confidence.** `present_clear_window_notifies()` only nulls `notify->window`, never
   unlinks the notify from its list; `present_destroy_window()` then frees the struct holding that
   list head. A still-linked notify (owned by a pending vblank on a *different* window) later gets
   unlinked via `xorg_list_del()`, writing through prev/next pointers into freed memory. Trigger:
   `PresentPixmap` on window A naming a notify list on window B with a far-future `target_msc`;
   destroy B before it fires; when A's presentation completes, freed memory is corrupted. Single
   client, deterministic, no OOM needed. **Cross-confirmed independently by Pegasus's blind
   re-check (via `present_notify.c:33-44` + `present_screen.c:101-126`) — this is one of the three
   deterministic non-OOM bugs Enterprise flagged as highest priority in m0130.**
2. **`Xext/dri2/dri2.c:545,593-602` — OOB heap write, high confidence.** `do_get_buffers()` allocs
   `calloc(min(count,10)+1, ...)` but its loop always runs `count` iterations regardless of
   dedup-`continue`s, so `i == count` unconditionally after the loop; with `count == 11` and no
   `DRI2BufferFrontLeft` requested, the `need_real_front` branch writes `buffers[11]`, one past the
   11-element allocation. Trigger: any DRI2-capable client sends `DRI2GetBuffers` with 11 attachment
   entries all `DRI2BufferBackLeft` — deterministic, no OOM required (CWE-787).
3. **`Xext/render/render.c:999-1006` — resource leak, high confidence.** `ProcRenderAddGlyphs`'s
   `bail:` path does `--glyph->refcnt; free(glyph);` directly instead of `FreeGlyph()`, skipping
   release of the glyph's realized Picture/Pixmap. Trigger: `X_RenderAddGlyphs` with glyph 0
   well-formed (realized) and glyph 1 malformed (`goto bail`) — glyph 0 leaks every request,
   repeatable DoS. **See also (Pegasus):** a second angle on the same `bail:` cleanup path, from
   the *multi-screen* side: inside `DIX_FOR_EACH_SCREEN` (around line 951), once a `Picture` is
   installed via `SetGlyphPicture()` for one screen, if pixmap/picture creation then fails for a
   *later* screen (multi-GPU config), the same `bail:` only decrements refcnt/frees the glyph
   struct — it never calls the per-screen equivalent of `FreeGlyphPicture()` for screens that
   already succeeded. Likely the same underlying missing-cleanup shape as this item, just reachable
   via a second (multi-screen) precondition — worth confirming both preconditions in one Phase 2
   fix rather than as two separate PRs.
4. **`Xext/xinput/exevents.c:2739-2748` (+ `dix/resource.c:833-836`, `InputClientGone` at
   `exevents.c:2822-2858`) — double-free, high confidence.** `AddExtensionClient()` links `others`
   as list head *before* `AddResource()`; if `AddResource`'s internal `calloc` fails, its
   `RT_INPUTCLIENT` delete callback (`InputClientGone`) already unlinks+frees `others` — but
   `AddExtensionClient`'s own `bail:` path still sees its local `others` as non-NULL and frees it
   again. Trigger: normal `XISelectEvents` path when `AddResource`'s internal `calloc` fails
   (memory pressure) — genuine heap-corruption primitive.
5. **`Xext/glx/unpack.h:62-79` (`__GLX_GET_ANSWER_BUFFER` macro) — stale-size NULL deref, high
   confidence (indirect GLX only).** `cl->returnBuf = realloc(cl->returnBuf, size+align)` assigns
   directly; on failure `returnBuf` is NULL but `returnBufSize` is left at its old (larger) value.
   A later request whose `size+align` fits under the stale `returnBufSize` skips the realloc branch
   and derefs the NULL buffer. `indirect_util.c:86-94`'s `__glXGetAnswerBuffer()` does the same
   operation correctly via a temporary, confirming this macro is the outlier. **Cross-confirmed
   independently by Pegasus's blind re-check**, which additionally names the concrete crash site:
   `glReadPixels` (`singlepix.c:75-79`) writing GL pixel data straight into the NULL buffer — a
   remotely-triggerable NULL-pointer *write* via indirect GLX, not just a read.
6. **`Xext/xinput/exevents.c:675-684`, `DeepCopyPointerClasses()` — NULL deref, traced not
   independently reverified.** After `to->touch->touches = calloc(...)`, the failure check
   re-tests `if (!to->touch)` (always false) instead of `if (!to->touch->touches)`; a failed calloc
   reaches `TouchInitTouchPoint()` indexing the NULL pointer. Reached via normal
   `ChangeMasterDeviceClasses` device-hierarchy processing.
7. **`Xext/xkeyboard/maprules.c:103`, `InputLineAddChar()` — NULL deref on OOM.** `reallocarray()`
   growth path has no NULL check (unlike the sibling `calloc` branch above it); failure writes
   through NULL while parsing an XKB rules/mapping file.
8. **`Xext/xkeyboard/xkb.c:2287`, `SetKeyBehaviors()` (via `XkbSetMap`) — self-overwriting
   realloc**, and **`xkb.c:3025`, `_XkbSetCompatMap()` (via `XkbSetCompatMap`, client-controlled
   size `req->firstSI+req->nSI`) — same pattern.** Both leak the prior buffer on OOM.
9. **`Xext/randr/rrlease.c:330-336`, `ProcRRCreateLease()` — leak, not unlink-on-`AddResource`-fail.**
   `lease` is linked into `scr_priv->leases` before `AddResource()`; on failure it's never
   unlinked/freed, permanently marking its CRTCs/outputs as leased since the client never got a live
   XID to free it with. Same shape recurs (lower severity) in `rrmode.c:93-96`, `rrcrtc.c:101`,
   `rroutput.c:101`, `rrprovider.c:400`.
10. **`mi/midispcur.c:106-112`, `miDCInitialize()` — dangling devPrivates slot.** Stores
    `pScreenPriv` into `devPrivates` *before* `miSpriteInitialize()`; on failure `pScreenPriv` is
    freed but the slot isn't cleared. Most DDX callers (vfb/kdrive/xfree86/xnest/xwin) ignore the
    `Bool` return, so a later `dixLookupPrivate()` (e.g. `miDCSwitchScreenCursor`) derefs freed
    memory — gated on an alloc failure during `miSpriteInitialize` at screen init.
11. **`miext/rootless/rootlessScreen.c:115-132`, `RootlessUpdateScreenPixmap()` — dangling screen
    pixmap.** Frees `pixmap_data`, bumps `pixmap_data_size` to the new size, *then* `calloc`s the
    replacement; on failure the screen pixmap points at freed memory, and since the size was
    already bumped, a later same/smaller resize skips reallocation forever. Rootless (Xquartz-style)
    backend only. **Cross-confirmed independently by Pegasus's blind re-check** (same file, lines
    113-121) — identical mechanism, additionally noting the next `CopyArea`-style draw op onto the
    root/screen pixmap is the concrete UAF trigger.

### Additional findings from Pegasus's blind re-check of `dix/`, `os/`, `Xext/`, `mi/` — NOT covered above, some CONTRADICT a "nothing solid found" verdict

**⚠ Tie-breaker needed before Phase 2 skips these — Constellation's sweep explicitly listed
`Xext/security/`, `Xext/xselinux/`, `Xext/xv/`, and `mi/miwideline.c` as checked with nothing
solid found; Pegasus's independent (blind) pass over the same files found the below. Recommend a
third read before committing Phase 2 effort either way.**

12. **`mi/micmap.c:486-491`, `miInitVisuals()` — invalid-pointer `free()`, high confidence, genuinely
    new (file not in Constellation's checked list).** In the per-visual-type loop, `vid =
    calloc(nvtype, sizeof(VisualID))` failure frees `depth`/`visual`/`preferredCVCs` — but on the
    2nd+ iteration `depth` (incremented at line 535) and `visual` (incremented at lines 532-533)
    have already been advanced past the base pointers originally returned by the top-level
    `calloc`s (lines 460-461). `free()` on these mid-buffer pointers is undefined behavior; glibc
    aborts with "free(): invalid pointer" — crashes the server on an OOM hit with more than one
    display depth registered (the normal multi-depth case).

13. **`mi/miwideline.c:477-501`, `miFillUniqueSpanGroup()` — double-free, high confidence per
    Pegasus's agent; CONTRADICTS Constellation's "nothing solid found" for this file.**
    `newpoints = reallocarray(newspans->points, ...)` and `newwidths =
    reallocarray(newspans->widths, ...)` run back to back. If the first succeeds (freeing/moving
    the old `points` block) and the second fails, the cleanup loop `for (i = 0; i < ylength; i++)
    { free(yspans[i].points); free(yspans[i].widths); }` frees `yspans[index].points` again — the
    stale, already-invalidated pointer, since `newspans->points = newpoints` hasn't executed yet.
    Trigger: drawing enough overlapping wide/dashed lines/arcs to force a y-bucket span-array
    growth under OOM. Symmetric case (widths succeeds, points fails) hits the same bug on
    `widths`. **Needs a fresh read to resolve the disagreement with Constellation before Phase 2.**

14. **`Xext/security/security.c:511-571`, `ProcSecurityGenerateAuthorization()` — double-free,
    high confidence per Pegasus's agent; CONTRADICTS Constellation's "nothing solid found" for
    `Xext/security/`.** If `AddResource(authId, SecurityAuthorizationResType, pAuth)` fails because
    `AddResource`'s internal `calloc` fails (`dix/resource.c:833-836`), `AddResource` itself invokes
    `SecurityDeleteAuthorization(pAuth, authId)`, which already calls `RemoveAuthorization()` and
    `free(pAuth)` (security.c:230). Control returns FALSE; `ProcSecurityGenerateAuthorization` then
    does `goto bailout`, where `bailout:` unconditionally calls `RemoveAuthorization()` again and
    `free(pAuth)` again — a double-free plus a duplicate `RemoveAuthorization` call, remotely
    triggerable via `SecurityGenerateAuthorization` under an OOM hit in the resource table. **Needs
    a fresh read to resolve the disagreement with Constellation before Phase 2.**

15. **`Xext/xv/xvmc.c:225-263` / `:380-458`, `ProcXvMCCreateSurface`/`ProcXvMCCreateSubpicture` —
    premature refcnt decrement → UAF, high confidence per Pegasus's agent; CONTRADICTS
    Constellation's "nothing solid found" for `Xext/xv`.** `pContext->refcnt++` runs only after
    `AddResource()` succeeds. If `AddResource()` fails, it auto-invokes
    `XvMCDestroySurfaceRes`/`XvMCDestroySubpictureRes`, which unconditionally call
    `XvMCDestroyContextRes()` and decrement `pContext->refcnt` even though the matching increment
    never happened. If `refcnt` was 1, it drops to 0, freeing `pContext` (and calling the driver's
    `DestroyContext`) while the pre-existing `context_id` resource-table entry still points at the
    freed struct. Any later op on that `context_id` is a use-after-free. **Needs a fresh read to
    resolve the disagreement with Constellation before Phase 2.**

16. **`Xext/xselinux/xselinux_label.c:67`, `SELinuxArraySet()` — self-overwriting `reallocarray`,
    high confidence per Pegasus's agent; CONTRADICTS Constellation's "nothing solid found" for
    `Xext/xselinux`.** `rec->array = reallocarray(rec->array, key + 1, sizeof(val))` overwrites the
    sole array pointer before the NULL check; on failure `rec->array` becomes NULL while
    `rec->size` is unchanged, so a later `SELinuxArrayGet()` with `key < rec->size` dereferences
    NULL. **Needs a fresh read to resolve the disagreement with Constellation before Phase 2.**

17. **`Xext/xkeyboard/xkbLEDs.c:638-641`, `XkbFindSrvLedInfo()` — unchecked calloc → NULL write,
    high confidence, genuinely new (different file than Constellation's xkeyboard findings).**
    `sli->names`/`sli->maps` calloc'd without a NULL check, but the function still returns non-NULL
    `sli`. Called from `SetDeviceIndicators` (`xkb.c:6628-6673`, handling `XkbSetDeviceInfo`), which
    only checks `sli` itself, then does `memset(sli->maps, ...)` and `sli->maps[n].flags = ...`
    unconditionally — NULL pointer write/crash from a single client request under OOM.

18. **`dix/dispatch.c:3153-3172`, `ProcCreateCursor()` — NOT an alloc/UAF bug, flagged as a bonus
    find, high confidence.** `size_t n = BitmapBytePad(width) * height; while (--n >= 0) *bits++ =
    ~0;` — `n` is unsigned so `--n >= 0` is always true: an effectively infinite loop that overflows
    the `mskbits` buffer whenever mask is `None`. Trivially triggerable via a single `CreateCursor`
    request; heap buffer overflow / crash. Different bug class from this sweep's brief but serious
    enough to flag now rather than wait for a dedicated pass.

## Findings: `hw/xfree86/common/` + `hw/xfree86/os-support/` (Constellation)

1. **`hw/xfree86/common/xf86Config.c:1163-1178` + `:1261-1276`, `checkCoreInputDevices()` — NULL
   deref via a stale-flag logic bug, high confidence.** `foundPointer`/`foundKeyboard` start TRUE;
   `Pointer = xf86AllocateInput()` (can return NULL) is only followed by `if (Pointer)
   foundPointer = configInput(...)` — if NULL, `foundPointer` keeps its prior TRUE value and the
   next `if (foundPointer) { Pointer->options = ...; }` derefs NULL. Duplicated for
   `Keyboard`/`foundKeyboard`. Trigger: OOM during startup at core-pointer/-keyboard allocation.
2. **`hw/xfree86/common/xf86platformBus.c:65-92` (+ derefs at `xf86Bus.c:330,822`,
   `xf86platformBus.c:126,385,402,416,482,875`) — UAF via array-move-without-pointer-fixup, high
   confidence.** `xf86_platform_devices` is a single global array grown via `XNFreallocarray()` and
   compacted via in-place `memcpy` on removal, but long-lived structures (`EntityRec.bus.id.plat`,
   `primaryBus.id.plat`) store **raw pointers into array elements**, never fixed up on
   grow/compact. Trigger: confirmed reachable — `xf86platformProbe()` registers
   `xf86PlatformDeviceProbe` as the udev hotplug callback for the server's lifetime; a later
   hotplug (e.g. plugging in a GPU) grows the array via `XNFreallocarray()`; if the block moves,
   every previously-captured pointer is now dangling. Unplugging causes the same corruption via the
   compaction `memcpy` even without a realloc move.
3. **`hw/xfree86/os-support/shared/seatd-libseat.c:227-237` + `:246-255` — double-close/UAF.** On
   `libseat_handle_events(100) < 0` inside `seatd_libseat_init()`, `libseat_close_seat()` is called
   but `seat_info.client` is never reset to NULL and its notify fd stays registered;
   `seatd_libseat_fini()`'s own `if (seat_info.client)` guard is still true (dangling), closing it
   again at shutdown. Trigger: `-keeptty` startup where `libseat_open_seat()` succeeds but the first
   `libseat_handle_events()` fails/times out.
4. **`hw/xfree86/common/xf86Configure.c:322` — self-overwriting realloc, low severity** (one-shot
   `Xorg -configure` process, small leak on OOM).
5. **`hw/xfree86/common/xf86AutoConfig.c:323-352`/`:416-419` — inconsistent global state on OOM.**
   `xf86ConfigLayout.screens` is reassigned to a fresh array before `copyScreen()`'s loop; if its
   internal `calloc` fails, the function returns leaving a partially-populated array as a live
   global and leaking the old array. Narrow (OOM + multi-driver autoconfig only).
6. **`hw/xfree86/common/xf86sbusBus.c:175`, `SBUS_DEVICE_FFB` case — NULL deref, SPARC/SBus only.**
   `prop`'s NULL-guard only covers the `chiprev` assignment; the following `strstr(prop, "afb")` is
   unconditional, unlike the sibling `CG14`/`LEO` cases. Trigger: probing an FFB framebuffer node
   without a 4-byte `board_type` PROM property.

Noted but out of the requested bug classes: `xf86DGA.c:1507-1509`/`:1572-1574` have an inverted
`if (pScreen) return BadValue;` check (should be `!pScreen`), letting an out-of-range client-
supplied screen index reach `screenInfo.screens[]` unchecked — an OOB array index, not
alloc-fail/UAF, flagged for awareness only. No confident findings in the remaining common/ files or
in any `os-support/{linux,bsd,hurd,solaris,bus,misc,stub}` — those either use the abort-on-failure
`XNF*` allocator family or are correctly guarded.

### Additional findings from Pegasus: `hw/xfree86/common/` (rest) + `hw/xfree86/parser/` + `Xext/composite/` + `glamor/`

7. **`Xext/composite/compwindow.c:598-641`, `compWindowUpdateAutomatic()` — NULL deref, high
   confidence, genuinely new (Composite not covered by Constellation).** `pSrcPicture`/
   `pDstPicture` from `CreatePicture()` (lines 598, 604) are never NULL-checked, unlike the sibling
   `compNewPixmap()` in `compalloc.c` which does guard this. `SetPictureClipRegion(pDstPicture, 0,
   0, pRegion)` (line 629) unconditionally dereferences `pDstPicture->pDrawable`, and lines 640-641
   unconditionally call `FreePicture()` on both, dereferencing `->refcnt`. Trigger: `CreatePicture`
   fails (e.g. under memory pressure) while repainting a window using
   `CompositeRedirectAutomatic` — a normal, frequent, remotely-triggerable path — immediate
   NULL-pointer-dereference crash on the next window repaint.

8. **`glamor/glamor_egl.c:1222` and `:1290`, `glamor_pixmap_from_fds()`/`glamor_pixmap_from_fd()` —
   NULL deref, high confidence, genuinely new (glamor explicitly unscanned until now).**
   `pixmap = screen->CreatePixmap(...)` is never checked for NULL before being passed into
   `screen->ModifyPixmapHeader()`, `glamor_egl_create_textured_pixmap_from_dma_bufs()`,
   `glamor_back_pixmap_from_fd()`, or `dixDestroyPixmap()`. These are glamor's DRI3
   `PixmapFromBuffers`/`BuffersFromPixmap` screen hooks, reachable by any client via DRI3. If the
   underlying `fbCreatePixmap` malloc fails, `glamor_back_pixmap_from_fd()` immediately
   dereferences `pixmap->drawable.pScreen` — NULL-pointer-dereference crash (remote DoS under
   memory pressure).

9. **`hw/xfree86/common/xf86Config.c:184`, `xf86ValidateFontPath()` — unchecked calloc, high
   confidence.** `tmp_path = calloc(1, strlen(path) + 1); out_pnt = tmp_path;` with no NULL check
   before `out_pnt` is later passed to `strcat(out_pnt, path_elem)`. Trigger: `calloc` fails while
   validating the configured `FontPath` at startup under memory pressure → `strcat(NULL, ...)`
   crash.

10. **`hw/xfree86/common/xf86Configure.c:470-473`, `handle_detailed_input()` (EDID parsing in
    `-configure` mode) — assert-instead-of-NULL-check, high confidence. Different bug/lines from
    Constellation's item 4 (line 322) in the same file — both real, keep separate.**
    `ptr->mon_modelname = realloc(...); assert(ptr->mon_modelname); strcpy(...)`. Trigger: `realloc`
    fails (OOM) and the build has asserts disabled (`NDEBUG`/`-Db_ndebug=true`, common in release
    packaging) → `strcpy` into NULL → crash. Independent of assert state, the old buffer is leaked
    on failure.

11. **`hw/xfree86/parser/Files.c:116-117` and `:130,142-143`, `xf86parseFilesSection()` — same
    assert-instead-of-NULL-check pattern, high confidence, genuinely new (parser/ not covered
    above).** `ptr->file_fontpath = realloc(...); assert(...); strcat(...)` and
    `ptr->file_modulepath = calloc(1,1)/realloc(...); assert(...); strcat(...)`. Trigger: OOM while
    parsing `xorg.conf` FontPath/ModulePath with asserts disabled → `strcat` into NULL → crash.

12. **`hw/xfree86/parser/scan.c:705` (`OpenConfigFile`) and `:802` (`OpenConfigDir`) — unchecked
    strdup, high confidence.** `pathcopy = strdup(path);` unchecked, then `strtok(pathcopy, ",")`.
    Trigger: `strdup` fails (OOM) during early config-file search at startup →
    `strtok(NULL, ",")` on the very first call is undefined behavior.

13. **`hw/xfree86/common/xf86Bus.c:284` (`StringToBusType`) and
    `hw/xfree86/common/xf86pciBus.c:285` (`xf86ParsePciBusString`) — unchecked Xstrdup, high
    confidence.** `s = Xstrdup(busID)` / `Xstrdup(id)` unchecked, then `strtok(s, ":")`. Trigger:
    `Xstrdup` OOM while parsing a configured `BusID`.

14. **`hw/xfree86/common/xf86platformBus.c:303-306` and `:329-332` — unchecked strdup feeding
    `strtok_r` with an uninitialized saveptr, high confidence. Different bug/lines from
    Constellation's item 2 (array-move UAF) in the same file — both real, keep separate.**
    `char *copy = strdup(cl->modules ? cl->modules : "");` unchecked; `curr = copy` (NULL on
    failure) passed as the first arg to `strtok_r(curr, ",", &next)` with `next` an uninitialized
    stack variable. Since the first arg is NULL, `strtok_r` treats this as a *continuation* call
    and reads the uninitialized `next`/`*saveptr` as a resume position — dereferences
    uninitialized/garbage stack pointer.

## Findings: `xf86-video-intel` + `xf86-video-amdgpu` (Constellation)

1. **`xf86-video-intel/src/sna/sna_stream.c:53`, `sna_static_stream_alloc()` — self-overwriting
   realloc, high confidence.** `stream->data = realloc(stream->data, stream->size)` with no NULL
   check; `stream->used` is bumped regardless. Trigger: driver init's 64KB shader-kernel/state
   buffer grows via `sna_static_stream_add()`; on OOM, callers immediately `memcpy`/`memset` through
   the now-NULL `stream->data` — crash during driver init. **Cross-confirmed independently by
   Pegasus's video-driver sweep (exact same file/line).**
2. **`xf86-video-amdgpu/src/amdgpu_kms.c:468`, `transform_region()` — unchecked `malloc`, high
   confidence.** No NULL check before the loop unconditionally writes `rects[nrects].*`. Reachable
   from `amdgpu_sync_scanout_pixmaps()` (TearFree) and `dirty_region()` (rotated/transformed
   outputs) — both normal-use paths, not exotic. **Cross-confirmed independently by Pegasus's
   video-driver sweep (line 471, same bug).**
3. **`xf86-video-amdgpu/src/amdgpu_bo_helper.c:198-199`, `amdgpu_pixmap_get_handle()` — unchecked
   calloc, high confidence.** `priv = calloc(...)` stored as the pixmap private, then
   `priv->handle_valid` dereferenced unconditionally on the very next line. On a common path
   (DRI2/DRI3/Present/tiling queries). **Cross-confirmed independently by Pegasus's video-driver
   sweep (lines 199-203, same bug).**
4. **`xf86-video-amdgpu/src/drmmode_display.c:2186-2192`, `drmmode_output_create_resources()` —
   two unchecked callocs, high confidence.** `tearfree_prop = calloc(...)` and its `->enums =
   calloc(...)` are both dereferenced/`strcpy`'d unconditionally — inconsistent with the correctly
   NULL-checked `props` calloc three lines earlier in the same function. Runs once per connector at
   startup/hotplug/re-probe. **Cross-confirmed independently by Pegasus's video-driver sweep (lines
   2188-2197, same bug) — Pegasus additionally found a related "counted-but-NULL atoms" pattern in
   the same file (lines 2212-2215/2243-2246, used at 1875/1890/2340): when `p->atoms =
   calloc(...)` fails, the code `continue`s but `p->num_atoms` was already incremented, so
   `drmmode_output_set_property()`'s `p->num_atoms && p->atoms[0] != property` check treats truthy
   `num_atoms` as proof `atoms` is valid and dereferences NULL — new addition, not previously
   listed for amdgpu.**

**New from Pegasus (amdgpu):** `src/amdgpu_drm_queue.c:353-363` (lists at 54-57) —
`amdgpu_drm_queue_close(scrn)` only scans the pending queue list for `scrn`, never the shared
`amdgpu_drm_flip_signalled`/`amdgpu_drm_vblank_signalled`/`amdgpu_drm_vblank_deferred` lists. In
multi-screen/Zaphod configs, an event already moved to a signalled/deferred list survives screen
A's teardown; a later drain by screen B's event loop dereferences `e->crtc->driver_private` on a
freed object — UAF. Confidence: moderate (mechanism confirmed, exact multi-screen teardown
ordering not fully traced).

No confident BO-refcounting UAF in either driver (DRI2/DRI3/Present/glamor BO exchange and
page-flip queues were traced and ref/unref pairing holds). `xf86-video-ati` has a fully separate
`src/` tree from amdgpu/intel — **now scanned by Pegasus, see the new `xf86-video-ati` section
below.**

**New from Pegasus (intel), genuinely new files beyond `sna_stream.c`:**
- `src/uxa/i965_render.c:2350` — `calloc()` for `gen4_render_state` guarded only by `assert()`,
  compiled out (`NDEBUG`) in default release builds. NULL deref on OOM during EnterVT/mode-set on
  gen4/gen5 hardware.
- `src/uxa/intel_display.c:711-726` — `intel_crtc_init()`: on `drmModeGetCrtc()` failure,
  `intel_crtc` is freed but the already-`xf86CrtcCreate()`'d, already-registered `xf86CrtcPtr` is
  never destroyed, left with `driver_private` unset. Any later crtc-vtable call dereferences NULL.
- `src/sna/sna_accel.c:1340` — on `sna_pixmap_attach()` failure in `sna_create_pixmap()`, the
  pixmap header is released with plain `free()` instead of `FreePixmap()` (every other error path
  in the file correctly uses `FreePixmap()`), skipping `dixFiniPrivates()` teardown. Lower
  confidence — leak/invariant-skip, not a direct crash.
- `src/sna/sna_trapezoids_boxes.c:284-285` — `pixman_region_fini(&region)` called twice on the same
  region in `composite_aligned_boxes()`'s per-box fallback loop — double-free of `region->data`.
  Reachable via `XRenderCompositeTrapezoids` with axis-aligned boxes against a picture with a
  non-trivial (multi-rect) clip when the accelerated composite path declines.

## Findings: `xf86-video-nouveau` + `xf86-video-vmware` + `xf86-video-qxl` (Constellation)

1. **nouveau, `src/drmmode_display.c:1438-1441` — unchecked malloc, dangling shadow-FB pointer,
   high confidence.** `drmmode_xf86crtc_resize()` frees `pNv->ShadowPtr` then unconditionally
   reassigns it from `malloc()` with no NULL check; `ShadowFB` stays enabled regardless. Trigger:
   `Option "ShadowFB" "true"` + a RandR resize (`xrandr --fb WxH`) that fails to allocate — the next
   damage refresh (`nv_shadow.c:51-58`) `memcpy`s from `NULL + offset`. **Cross-confirmed
   independently by Pegasus's video-driver sweep (exact same file/lines).** Pegasus additionally
   found the *init-time* twin of this bug, genuinely new: `src/nv_driver.c:1414` — same unchecked
   `malloc()` for `pNv->ShadowPtr` in `NVScreenInit`'s ShadowFB setup (not just the resize path),
   and a separate unrelated finding in the same file: `src/nv_driver.c:895-896` —
   `pScrn->chipset = malloc(25)` unchecked before `sprintf()` into it during `NVPreInit`.
2. **vmware, `vmwgfx/vmwgfx_dri3.c:133-148` + `vmwgfx_saa.c:794-849` — double-unref, high
   confidence.** `vmwgfx_dri3_pixmap_from_fd()`'s `out_no_damage:` path in `vmwgfx_create_hw()`
   already does `xa_surface_destroy(hw)` (== `xa_surface_unref`) on `DamageCreate()` failure; the
   caller's own `out_no_damage:` label unrefs the same surface again. Trigger: DRI3
   `PixmapFromBuffer` while `DamageCreate()` fails under memory pressure.
3. **vmware, `vmwgfx/vmwgfx_output.c:213-235` (alloc) / `:365-368`,`:470-472` (use) — NULL deref,
   high confidence.** A connector property slot is counted in `num_props` before its `p->atoms =
   calloc(...)` is attempted; on failure the slot stays counted with `atoms == NULL`, and
   `output_set_property()`/`output_get_property()` unconditionally read `p->atoms[0]`. Trigger: an
   output-property calloc fails during connector enumeration; next
   `RRChangeOutputProperty`/`RRGetOutputProperty` on that output crashes.
4. **qxl, `src/qxl_surface_ums.c:715-734` — UAF via dangling external list head, high confidence.**
   `qxl_surface_kill()` unlinks+frees a node but can't update the external head pointer
   `qxl->vt_surfaces` (owned by `qxl_driver.c`) if the killed node was the head. Trigger: VT-switch
   away sets `vt_surfaces` to the current head; while off-VT, a client destroys the pixmap backed by
   that head surface (frees it without fixing the head pointer); switching back derefs the freed
   node via `qxl_surface_cache_replace_all()`. **Cross-confirmed independently by Pegasus's
   video-driver sweep (lines 716-734, same bug).**
5. **qxl, `src/qxl_surface_ums.c:828-830` — NULL deref on VT re-entry, high confidence.**
   `qxl_surface_cache_replace_all()` derefs `surface->host_image` right after `qxl_surface_create()`,
   which can legitimately return NULL (out of video memory/surfaces) — no NULL check. Trigger: VT
   re-entry when too little device memory remains to recreate all evacuated surfaces.
6. **qxl, `src/qxl_surface_ums.c:774` — unchecked malloc, high confidence.** `evacuated_surface_t
   *evacuated = malloc(...)` used without a NULL check, unlike the careful OOM-retry loops used
   elsewhere in the same file. Trigger: host memory pressure at VT-switch-away time.
   **Cross-confirmed independently by Pegasus's video-driver sweep (same line, same bug).**

**New from Pegasus (vmware, different files):**
- `src/vmware_common.c:134` — `extents = realloc(extents, ...)` in `VMWAREParseTopologyString`
  overwrites the only pointer without a NULL check; next line writes `extents[numOutputs-1].x_org`.
- `src/vmware.c:1160-1165` — `mode`/`modeName` mallocs in `VMWAREAddDisplayMode` unchecked before
  `memset`/`strcpy`.

**New from Pegasus (qxl, different lines):**
- `src/qxl_surface_ums.c:331` — `malloc()` for `surface` in `qxl_surface_cache_create_primary()`
  unchecked before `surface->id = 0`.
- `src/qxl_kms.c:684` — `calloc()` for `surface` unchecked before `surface->bo = bo`; also leaks
  the just-created `bo` (DRM ioctl result) if `surface` alloc fails.

## Findings: `xf86-input-libinput` + `xf86-input-wacom` + `xf86-input-synaptics` (Constellation)

1. **libinput, `src/xf86libinput.c:4331`, `update_mode_prop_cb()` — UAF, high confidence.** The
   deferred `QueueWorkProc` callback for tablet-pad mode-group updates derefs `pInfo->private`
   *before* the device-still-alive check that immediately follows it (a `nt_list_for_each_entry`
   walk clearly intended as that liveness check). Trigger: a mode-button press queues this
   callback; the tablet is unplugged (freeing the `InputInfoRec`) before the work queue drains;
   the callback then reads freed memory before its own safety check runs. **Cross-confirmed
   independently by Pegasus's input-driver sweep (exact same file/line/mechanism).**
2. **libinput, `src/xf86libinput.c:3958-3969`, `xf86libinput_create_subdevice()` — leak on OOM.**
   `calloc` failure for `hotplug` returns early, leaking the just-built `iopts` option chain
   (and its duplicated strings). Two more speculative issues (a `shared_device` refcount question
   around line 4089-4113, an `unclaimed_tablet_tool_list` leak in `xf86libinput_shared_unref()`)
   were surfaced but not fully traced — flagged for a follow-up look, not listed as confirmed.
3. **wacom, `src/x11/xf86Wacom.c:73-77`, `wcmLog()` — NULL write on OOM, high confidence.** The
   driver's universal logging function derefs an unchecked `calloc` — can crash while trying to log
   an unrelated OOM condition elsewhere.
4. **wacom, `src/x11/xf86Wacom.c:208-210`/`217`, `wcmTimerNew()`/`wcmTimerFree()` — NULL deref on
   OOM, high confidence.** Called up to 3× per new device during PreInit/hotplug.
5. **wacom, `src/wcmConfig.c:1070-1112`, `wcmDevOpen()` — fd-refcount double-increment, verified,
   100% reproducible (not OOM-gated).** For the sub-device that performs the actual open,
   `fd_refs` is incremented twice for one logical reference (`wcmGetFd(priv)` is still `-1` when the
   second `if` runs, since `wcmClose()` doesn't touch `fd_refs`); `wcmDevClose()`'s
   `if (!--common->fd_refs)` therefore never reaches zero — the fd leaks on every plug/unplug cycle.
6. **wacom, `src/x11/xf86Wacom.c:806-809`, `DEVICE_ON` — fd/ref leak if `wcmDevStart()` fails after
   `wcmDevOpen()` succeeded**, no matching close on that path.
7. **synaptics, `src/synaptics.c:1339`, `DeviceInit()` — unchecked alloc, high confidence.** The
   third of three `SynapticsHwStateAlloc()` calls (`priv->comm.hwState`) is the only one *not*
   NULL-checked; `SynapticsReset()` derefs it unconditionally right after. Trigger: OOM during
   `DEVICE_INIT` for any touchpad. **Cross-confirmed independently by Pegasus's input-driver sweep
   (exact same file/line).**
8. **synaptics, `src/synaptics.c:1188`/`1351`/`953-954` — double-free of `open_slots`, traced.**
   `DeviceInitTouch()`'s `malloc()` for `open_slots` happens before the two `hwState` allocations;
   if either fails, the `fail:` label frees `open_slots` without NULLing it, and
   `SynapticsUnInit()`'s later `if (priv->open_slots) free(...)` double-frees it. Trigger: OOM in
   `hwState`/`local_hw_state` alloc during `DEVICE_INIT`, reached via the normal
   `NewInputDeviceRequest` failure-unwind path.
9. **synaptics, `src/eventcomm.c:956-961`, `src/ps2comm.c:382-384`, `src/psmcomm.c:137-139` —
   unchecked proto-data allocs, high confidence.** All three protocol backends (evdev/PS2/PSM)
   store an unchecked `calloc`/alloc result as `priv->proto_data` and immediately dereference it —
   default paths hit on every touchpad `PreInit`/probe. **Cross-confirmed independently by
   Pegasus's input-driver sweep (all three files/lines match exactly).**

Nothing solid found in `xf86-input-libinput`'s smaller helpers (`bezier.c`, `draglock.c`,
`util-strings.c`), or beyond the items above in wacom/synaptics.

### New from Pegasus: `xf86-input-evdev`, `xf86-input-elographics`, `xf86-input-joystick`,
`xf86-input-keyboard`, `xf86-input-mouse`, `xf86-input-vmmouse`, `xf86-input-void`
(all genuinely unscanned before this — listed in the prior "still unscanned" section)

- `xf86-input-elographics` — no findings; unchecked `strdup` results (lines 899, 983) only ever
  used in a debug printf and `free()`, never dereferenced — no concrete crash path.
- `xf86-input-evdev/src/evdev.c:1409` (`EvdevAddAbsValuatorClass`), `:1713`
  (`EvdevAddRelValuatorClass`), `:1770` (`EvdevAddButtonClass`) — three sites, same pattern:
  `malloc()` for `atoms`/`labels` unchecked, then `memset`/array-writes into it via
  `EvdevInitAxesLabels`/`EvdevInitButtonLabels`. High confidence; also leaked on later `goto out`
  paths since cleanup only calls `EvdevFreeMasks`.
- `xf86-input-vmmouse` — no findings; all allocs NULL-checked, single free path, no double-free.
- `xf86-input-void` — no allocation calls exist in the file; nothing to audit.
- `xf86-input-joystick/src/backend_bsd.c:130-134` — `malloc(sizeof(struct
  jstk_bsd_hid_data))` unchecked, `bsddata->dlen = ...` immediately after.
- `xf86-input-joystick/src/backend_evdev.c:132-138` — `malloc(sizeof(struct jstk_evdev_data))`
  unchecked, dereferenced in following axis-init loop.
- `xf86-input-joystick/src/jstk_options.c:97` — `strdup(org)` unchecked, passed to `strcmp` in
  `jstkParseButtonOption`.
- `xf86-input-joystick/src/jstk_options.c:178` — `xstrdup(org)` (plain, non-aborting `Xstrdup`)
  unchecked, passed to `strstr` in `jstkParseAxisOption`.
- `xf86-input-keyboard/src/lnx_KbdMap.c:518-527` — wrong-pointer NULL check, high confidence.
  Checks `pKbd->specialMap` (already known non-NULL) instead of `pKbd->specialMap->map` (the
  just-allocated inner calloc). If the inner calloc fails, the failure goes undetected; line 595
  later does `pKbd->specialMap->map[i] = special` → NULL-pointer write. Requires `CustomKeycodes`
  option enabled plus a transient calloc failure at that specific call.
- `xf86-input-mouse/src/bsd_mouse.c:541-562` (`usbMouseProc`, `DEVICE_ON`) — **UAF, high
  confidence.** `free(pMse)` at line 548 (when `XisbNew` fails), then lines 558-560
  unconditionally execute `pMse->lastButtons = 0` etc. — dereferencing the just-freed pointer.
  `pInfo->private` is never nulled, so every subsequent call into the driver also dereferences
  freed memory.
- `xf86-input-mouse/src/mouse.c:829-830,839-840` (`MousePickProtocol`) combined with OS-specific
  `PreInit` implementations that `free(pMse)` on failure (`sun_mouse.c:211-225` vuidPreInit,
  `bsd_mouse.c:641-701` usbPreInit, `hurd_mouse.c:135-160` OsMousePreInit) — return value of
  `osInfo->PreInit(...)` is ignored, so `pMse->protocolID = protocolID` (mouse.c:932) writes
  through a `pMse` that may have already been freed on OOM; the USB/OSMouse path additionally
  leaves `pInfo->private` dangling while `MousePreInit` still reports `Success`.

Repos confirmed clean by both scope and depth: `xf86-input-vmmouse`, `xf86-input-void`,
`xf86-input-elographics`.

## New from Pegasus: `xf86-video-ati` (own tree, previously fully unscanned)

- `src/radeon_bo_helper.c:298-306` — `radeon_bo_open()` return value never checked; NULL silently
  stored into `bo->bo.radeon`, wrapper `bo` (always non-NULL) returned as if success. Later
  `radeon_get_pixmap_handle()` (line 363) or `radeon_bo_set_tiling` derefs NULL under VRAM/GTT
  pressure.
- `src/radeon_bo_helper.c:501-503` — same pattern in PRIME/DRI3 import path: `if (!bo)` tests the
  always-true wrapper instead of `bo->bo.radeon`, missing a `radeon_gem_bo_open_prime()` failure.
- `src/drmmode_display.c:390-395` — same pattern in `create_pixmap_for_fbcon()`.
- `src/radeon_bo_helper.c:374-379` — `calloc()` for `priv` in `radeon_get_pixmap_handle()` (glamor
  path) unchecked; `priv->handle_valid` dereferenced immediately.
- `src/radeon_kms.c:429` — `malloc()` for `rects` in `transform_region()` unchecked before loop
  writes; large/rotated CRTC scanout update under memory pressure crashes.
- `src/drmmode_display.c:1696-1706` — `calloc()` for `tearfree_prop` and `tearfree_prop->enums`
  unchecked before field writes/`strcpy` in `drmmode_output_create_resources()` — same shape as
  the amdgpu/freedreno "tearfree_prop" bug (this codebase clearly shares a common origin for
  drmmode_display.c across the AMD-derived drivers).

Not reviewed line-by-line: shader/codegen files, most EXA accel backends. A suspected DRI2
deferred-event double-free/UAF was investigated but not confirmed — worth a second look.

## New from Pegasus: `xf86-video-freedreno` (previously fully unscanned)

- `src/msm-driver.c:244-303` and `565-568` — **double free, high confidence.** `MSMPreInit()`
  calls `free_msm(pMsm)` directly on several error paths without resetting
  `pScrn->driverPrivate` to NULL; `xf86DeleteScreen()` then unconditionally calls
  `MSMFreeScreen()` → `free_msm(pMsm)` again on the same pointer — triggerable by ordinary
  xorg.conf misconfiguration (bad Weight/DefaultVisual/Gamma) or OOM.
- `src/msm-driver.c:128-137, 565-568` — `free_msm()` dereferences `pMsm->drmFD` without a NULL
  check on `pMsm`; if `MSMPreInit()` returns FALSE before `driverPrivate` is ever allocated,
  `xf86DeleteScreen()` → `MSMFreeScreen` → `free_msm(NULL)` crashes.
- `src/drmmode_display.c:767-859` (esp. 793-796, 816-819) — same "counted-but-NULL atoms" pattern
  as amdgpu; `drmmode_output_set_property()`/`get_property()` dereference `p->atoms[0]`
  unconditionally.
- `src/msm-exa.c:982-988` and `src/msm-exa-xa.c:804-811` — `pMsm->exa = calloc(...)` unchecked; the
  adjacent NULL check only covers the unrelated `pMsm->pExa`.
- `src/msm-dri2.c:115-117` — `calloc()` for `pPriv` in `MSMDRI2GetDrawable()` unchecked,
  dereferenced next line; hit on every DRI2 buffer-create/swap-dispatch.
- `src/msm-dri2.c:525-527` — `calloc()` for `cmd` in `MSMDRI2ScheduleSwap()` unchecked,
  dereferenced immediately; hit on every DRI2 SwapBuffers.
- `src/fbmode_display.c:585-592` — `calloc()` for `fbmode` unchecked before `fbmode->fd =
  open(...)`.

## New from Pegasus: `xf86-video-nv` (previously fully unscanned)

- `src/g80_display.c:779-780` — `calloc()` for `g80_crtc` unchecked before `g80_crtc->head = head`
  in `G80DispCreateCrtcs`.
- `src/nv_driver.c:2379` and `src/riva_driver.c:1066` — `ShadowPtr` malloc unchecked, `FBStart`
  passed straight into `fbScreenInit()`.
- `src/riva_driver.c:108-111` — `calloc()` for `pScrn->driverPrivate` unchecked in
  `RivaGetRec()`; dereferenced next line; function still returns TRUE unconditionally.
- `src/nv_setup.c:249, 255-256` — (BSD wsdisplay `WSDISPLAYIO_GET_EDID` path) `malloc(1024)` EDID
  scratch buffer unchecked before ioctl; `xf86InterpretEDID()`'s return value dereferenced without
  a NULL check (returns NULL on malformed/incomplete EDID).

(See also `src/nv_driver.c:895-896` and `:1414` filed under the nouveau section above, since that
file lives in the shared nouveau/nv driver family tree.)

## New from Pegasus: `xf86-video-mga` (previously fully unscanned)

- `src/mga_merge.c:69-73` — two consecutive unchecked `malloc()`s (`mode`, `mode->Private`) in
  `CopyModeNLink()`, followed by `memcpy`/field writes.
- `src/mga_merge.c:238-239, 266-268` — unchecked `malloc()` for duplicated `ScrnInfoRec` and
  `MonRec` in `MGAPreInitMergedFB()`, followed by `memcpy`.
- `src/mga_merge.c:476-477, 485-486` (duplicated in `src/mga_driver.c:2023-2024, 2032-2033`) —
  unchecked `malloc()` for `linePitches` followed by `memcpy`, during mode validation.
- `src/mga_driver.c:2909` — `ShadowPtr` malloc unchecked, `FBStart` passed to `fbScreenInit()`.
- `src/mga_dri.c:703-704` — `busIdString` malloc(64) unchecked before `sprintf()`.

## New from Pegasus: `xf86-video-savage` (previously fully unscanned)

- `src/savage_vbe.c:350-362` (deref'd at 371) — `s3vModeTable->RefreshRate` reassigned via
  unchecked `realloc()`/`calloc()` in `SavageGetBIOSModes()`, written into right after.
- `src/savage_driver.c:3164` — `ShadowPtr` malloc unchecked, `FBStart` fed into
  `fbScreenInit()`/`fbOverlayFinishScreenInit()`.
- `src/savage_dri.c:597-598` — `busIdString` malloc(64) unchecked before `sprintf()` (other
  allocations in the same function correctly handle failure).

## New from Pegasus: `xf86-video-siliconmotion` (previously fully unscanned)

No findings — all sites checked use `XNFcalloc*` or have proper NULL checks/cleanup. No
`realloc()` calls exist. No DRI source file present.

## New from Pegasus: sampling pass across ~32 remaining `xf86-video-*` legacy drivers
(varying depth — not exhaustive; see per-repo notes)

**Real bugs found:**
- `xf86-video-voodoo/src/voodoo_driver.c:721-722` and `747-748` — **double free.**
  `VoodooCloseScreen` frees `pVoo->ShadowPtr` without nulling it; `VoodooFreeScreen` (runs after
  CloseScreen on normal shutdown) frees the same pointer again since its guard is still true.
- `xf86-video-omap/src/drmmode_display.c:1361-1374` (`drmmode_page_flip`) — **UAF.** On a
  multi-CRTC page flip, if `drmModePageFlip()` succeeds on an earlier CRTC but fails on a later
  one, the error path `free(flipdata)`s while the kernel still holds a pending page-flip event
  referencing `flipdata` as `user_data` for the CRTC that already succeeded; the later completion
  callback dereferences/frees it again.
- `xf86-video-omap/src/drmmode_display.c:522` — `calloc()` for `cursor` unchecked before
  `cursor->ovr = ovr` in HW cursor plane init.
- `xf86-video-geode/src/z4l.c:1625-1643` — cleanup loop after failed V4L2 Xv adaptor probe reuses
  outer loop variable `i` inside two nested cleanup loops, corrupting the outer index; with
  `nadpts > 1`, causes an out-of-bounds `adpts[i]` access / garbage pointer passed to `free()`.
- `xf86-video-v4l/src/v4l.c:925-926` — `p->standard = realloc(...)` unchecked, immediately
  `memcpy`'d into, during `VIDIOC_ENUMSTD` iteration in `V4LGetStd()`.
- `xf86-video-v4l/src/v4l.c:941-946` — same missing-check pattern in the ENUMSTD-unsupported
  fallback branch, with a direct `strcpy`.
- `xf86-video-v4l/src/v4l.c:261-262` — `malloc()` for a control-name buffer in `AddControl()`
  unchecked before `strcpy`/`strcat`.
- `xf86-video-sisusb/src/sisusb_driver.c:268-269, 274-275, 285-288` — three sites allocate
  `*nameptr` via bare `malloc()` and immediately `strcpy`/`sprintf` unchecked, during USB dongle
  device-node probing.

**Unchecked-alloc findings (ShadowFB pattern, repeated across many legacy drivers — same shape,
listed per-repo for Phase 2 triage):**
`xf86-video-apm/src/apm_driver.c:1645`, `xf86-video-chips/src/ct_driver.c:3579`,
`xf86-video-cirrus/src/alp_driver.c:1451`, `xf86-video-cirrus/src/lg_driver.c:1647`,
`xf86-video-neomagic/src/neo_driver.c:1382`, `xf86-video-rendition/src/rendition.c:983`,
`xf86-video-s3virge/src/s3v_driver.c:2419`, `xf86-video-sis/src/sis_driver.c:8192` — all
`ShadowPtr = malloc(...)` unchecked before being fed to `fbScreenInit()`/refresh handlers.

**Other unchecked-alloc findings:**
- `xf86-video-chips/src/ct_ddc.c:173-174` — `malloc(sizeof(CHIPSI2CRec))` unchecked, dereferenced
  next line during DDC/I2C setup.
- `xf86-video-geode/src/gx_vga.c:88-92` — `malloc(VGA_BLOCK)` (256KiB) for `font_data` unchecked
  before an immediate 256KiB `memcpy`; hit on VT-enter/leave-graphics.
- `xf86-video-geode/src/lx_memory.c:87-88, 99-100, 129-130, 153-154` — `calloc()` in
  `GeodeAllocRemainder()`/`GeodeAllocOffscreen()` unchecked, dereferenced immediately.
- `xf86-video-geode/src/gx_driver.c:340, 501-503` (mirrored in `lx_driver.c:309, 481-483`) —
  `pGeode->vesa = calloc(...)` unchecked; dereferenced on BIOS mode restore.
- `xf86-video-nested/src/xlibclient.c:175-176` — `calloc()` for `pPriv` unchecked, dereferenced
  next line during nested-screen creation.
- `xf86-video-nested/src/nested_input.c:193-196` — `calloc()` for `map` unchecked, written into
  in a loop.
- `xf86-video-r128/src/r128_dri.c:780-785`, `xf86-video-sis/src/sis_dri.c:152-154` — `busIdString`
  malloc(64) unchecked before `sprintf()`.
- `xf86-video-sis/src/sis_opt.c:824-825` — `tempstr` malloc unchecked before `sscanf` writes,
  parsing "CRT2Pos" option.
- `xf86-video-vesa/src/vesa.c:258-259` — `calloc()` for `data->block` unchecked, multiple field
  writes follow, in `VESASetModeParameters()`.
- `xf86-video-vesa/src/vesa.c:1362` (used at 1388, 1396) — `malloc(16384)` for `pVesa->fonts`
  unchecked before `slowbcopy_frombus()` writes, during VT-switch-away save.
- `xf86-video-vesa/src/vesa.c:1569` — `malloc()` for `pVesa->pstate` unchecked before `memcpy()`,
  during mode-save on VT switch.

**Latent/fragile, not currently reachable as a live bug — noted for awareness only:**
- `xf86-video-v4l/src/v4l.c:234, 244` — dangling-pointer hazard on chained-realloc partial
  failure; not currently reachable given current callers.
- `xf86-video-vbox/src/hgsmimemalloc.c:85-93` — `HGSMIMAAlloc()`'s exclusivity-flag assignment is
  dead code (placed after a `return`); all current call sites are sequential so not live.
- `xf86-video-trident` — `ShadowPtr`/`DGAModes` freed without nulling in `TRIDENTCloseScreen`, but
  no reachable double-free path found since `TRIDENTFreeScreen` doesn't re-touch them.

**Repos sampled with no findings:** `ark`, `ast`, `dummy`, `fbdev`, `i128`, `i740` (one
acknowledged benign leak, not a crash/UAF), `mach64`, `suncg14`, `suncg3`, `suncg6`, `sunffb`,
`sunleo`, `suntcx`, `tdfx`, `xgi`.

## Methodology (for whoever scans the next component)

Enumerate every `malloc`/`calloc`/`realloc`/`reallocarray`(-family) call site in the target
directory (excluding `XNFalloc`/`XNFcalloc`-family, which abort internally by design — not a valid
finding), read enough surrounding context per site to confirm there's genuinely no NULL check
anywhere reachable before first use (not just "no check on the same line"). Separately trace
`free()`/`Xfree()` sites in the most complex multi-branch error/cleanup paths for double-free /
use-after-free, prioritizing connection-teardown / client-disconnect code (that's historically
where these cluster). Precision over volume — verify each finding by reading the actual call graph,
not just pattern-matching.

**Update from Pegasus's cross-check:** independent blind re-scanning of already-"covered" areas is
worth doing even under time pressure — it caught 4 areas (`Xext/security/`, `Xext/xselinux/`,
`Xext/xv/`, `mi/miwideline.c`) where two agents disagree on whether a bug exists, which is more
valuable signal for Phase 2 triage than either verdict alone. If claiming a "still unscanned" area
below, a second independent pass on a *supposedly already-clean* file is also useful once the
unscanned list is short.

## Phase 2 (m0130): `dix/`+`os/` cluster — DONE (Intrepid, 2026-07-07)

All 5 findings in this cluster fixed, one PR each (isolated agent clone, build-verified before
each PR — `dix/`+`os/` object files/libs rebuilt clean; the one FreeBSD/DragonFly-only branch in
`os/client.c` could not be locally compile-tested, no such toolchain available here — mirrors an
already-working adjacent pattern in the same function, relying on the FreeBSD CI lane):

1. **PR #3264** — `dix/getevents.c`: reset `numMotionEvents` to 0 alongside a failed motion-history
   `calloc`, so existing consumer guards treat the device as history-less instead of
   indexing/memcpy'ing through the NULL buffer.
2. **PR #3268** — `dix/registry.c`: `double_size()` now only commits `realloc()`'s result on
   success (temp-var pattern) instead of overwriting `*ptr` with NULL and calling
   `dixResetRegistry()`, which could crash walking `requests[]`/`events[]`/`errors[]` against a
   stale nonzero count over a now-NULL array.
3. **PR #3269** — `dix/ptrveloc.c`: `InitTrackers()` now only replaces the tracker buffer/count
   together on success; `InitPredictableAccelerationScheme()` bails out (matching its existing
   two other alloc-failure checks) instead of ever letting a device go live with
   `num_tracker == 0`, which every tracker access divides by.
4. **PR #3270** — `os/client.c`: added the same NULL check the adjacent macOS branch in the same
   function already has, before the FreeBSD/DragonFly `sysctl(KERN_PROC_ARGS)` call.
5. **PR #3272** — `os/log.c`: `LogSetDisplay()` now resets `saved_log_fname`/`saved_log_backup` to
   NULL after freeing them, closing the latent (not currently reachable) UAF/double-free gap.

All PRs pushed against `master`, reviewer team `X11Libre/dev` requested per each PR's config;
`hw/xfree86`/driver-code HW-reviewer rule (m0130) doesn't apply to this cluster (pure `dix/`/`os/`).

## Phase 2 (m0130): `xf86-input-{libinput,wacom,synaptics}` cluster — DONE (Agamemnon, 2026-07-07)

All 9 findings in this cluster fixed, one PR each (each in its own `scripts/worktree`-isolated
checkout of the driver's own GitHub repo — these are separate repos from `xserver` itself, each
with its own `master`; `mk-agent-clone`/incubator concept doesn't apply here, no release lines to
juggle). Build-verified where the local toolchain allowed: `xf86-input-libinput` and
`xf86-input-wacom` both have working `meson` setups here and were fully rebuilt (compile+link)
after each change — `xf86-input-wacom`'s `ENABLE_TESTS` target has a pre-existing, unrelated
`strdupa`/`_GNU_SOURCE` build failure on this host, confirmed present on unmodified `master` too
(not caused by any of these fixes), so only the main driver target was built there.
`xf86-input-synaptics` uses autotools and its `configure.ac` requires `xorg-server >= 25.0.0` via
pkg-config, but this host's system package is `21.1.16` (the workspace's own xlibre build isn't
pkg-config-registered) — could not locally build-verify those 3 fixes; they're minimal, mechanical
NULL-checks following the exact pattern already used a few lines above each change site in the
same functions, so risk is low, but flagging the gap for reviewers rather than silently claiming
"tested."

**xf86-input-libinput** (2 findings):
1. **PR #37** — `update_mode_prop_cb()`: moved the `driver_data = pInfo->private` deref to after
   the function's own liveness check (device may have been unplugged while this `QueueWorkProc`
   callback was pending) instead of before it — was reading through a possibly-freed `pInfo`.
2. **PR #38** — `xf86libinput_create_subdevice()`: free the just-built `InputOption` chain
   (`iopts`, with its duplicated name/value strings) on the `hotplug` calloc's OOM path instead of
   leaking it.

**xf86-input-wacom** (4 findings):
3. **PR #18** — `wcmDevOpen()`: the device that performs the actual fd open never gave itself its
   own fd reference inline, so the fallback "grab the common descriptor" block always ran for it
   too and double-counted `common->fd_refs` — meant the fd never reached refcount 0 on close,
   leaking it every plug/unplug cycle. Fixed by setting the opener's own fd at the point of open.
4. **PR #19** — `wcmLog()` (unchecked `calloc` before `vsnprintf`) and the
   `wcmTimerNew()`/`Free()`/`Cancel()`/`Set()` family (unchecked `calloc` in `New()`, no NULL guard
   in the other three) — all NULL-deref on OOM; made all four timer functions tolerate NULL,
   mirroring the pattern already used by the underlying xserver `TimerCancel()`/`TimerFree()`.
5. **PR #20** — `DEVICE_ON`: release the fd reference `wcmDevOpen()` just took if the following
   `wcmDevStart()` fails, mirroring what `DEVICE_OFF` already does — was leaking it on every
   start failure on an otherwise-opened device.

**xf86-input-synaptics** (3 findings, not locally build-verified — see above):
6. **PR #15** — `DeviceInit()`: added the missing NULL check on the third `SynapticsHwStateAlloc()`
   call (`priv->comm.hwState`, deref'd unconditionally by the `SynapticsReset()` right after); also
   fixed the `fail:` cleanup to use `SynapticsHwStateFree()` (was leaking `hwState`/
   `local_hw_state`'s nested `slot_state`/`mt_mask` allocations via raw `free()`) and to NULL
   `open_slots` after freeing it (`SynapticsUnInit()` frees it again unconditionally later —
   double-free on this exact failure path since `priv` outlives a failed `DeviceInit()`).
7. **PR #16** — `eventcomm.c`/`ps2comm.c`/`psmcomm.c`: all three protocol backends stored an
   unchecked alloc as `proto_data` and dereferenced it on the very next line(s) — hit on every
   touchpad PreInit/probe, not an exotic path. Added the missing NULL checks.

All 7 PRs requested `cepelinas9000`+`stefan11111` as reviewers per the m0130 HW-domain-routing rule
(these are all `xf86-input-*` driver repos) — **not** relying on green CI/bot-review alone, per
AGENTS.md "Route hardware-touching PRs to the HW domain experts before merge."

**Not fixed / left for a possible follow-up:** the two speculative, not-fully-traced libinput
issues noted in Phase 1 (`shared_device` refcount question, `unclaimed_tablet_tool_list` leak in
`xf86libinput_shared_unref()`) — flagged as unconfirmed there, didn't attempt a fix without first
resolving that.
