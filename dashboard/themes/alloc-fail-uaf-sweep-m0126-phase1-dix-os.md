---
slug: alloc-fail-uaf-sweep-m0126-phase1-dix-os
title: "Alloc-fail/UAF security sweep (praetor directive m0126) — Phase 1 findings"
category: parked
noted_by: "Farragut (m0126 directive) / Intrepid (dix/+os/) / Constellation (Xext+mi+miext, hw/xfree86, intel+amdgpu, nouveau+vmware+qxl, input drivers)"
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

**Still unscanned** — free ships should pick one and claim it here (or via agent-bus) before
starting, to avoid duplicate sweeps: `fb/`, `exa/`, `glamor/`, `xkb-config`/keyboard config data
paths outside `Xext/xkeyboard/` already covered, `xf86-video-ati` (own tree, not shared with
amdgpu/intel), and the ~30 not-yet-touched driver repos — video: `ark`, `ast`, `apm`, `chips`,
`cirrus`, `dummy`, `fbdev`, `freedreno`, `geode`, `i128`, `i740`, `mach64`, `mga`, `neomagic`,
`nested`, `nv`, `omap`, `r128`, `rendition`, `s3virge`, `savage`, `siliconmotion`, `sis`, `sisusb`,
`suncg14`, `suncg3`, `suncg6`, `sunffb`, `sunleo`, `suntcx`, `tdfx`, `trident`, `v4l`, `vbox`,
`vesa`, `voodoo`, `xgi`; input: `elographics`, `evdev`, `joystick`, `keyboard`, `mouse`, `vmmouse`,
`void`. Most of these are legacy/low-usage drivers — a follow-up pass should triage by relevance
(actively-shipped/hardware still in use) rather than scan all ~30 exhaustively.

## Findings

1. **`dix/getevents.c:384-387` (alloc-fail gap → NULL-pointer memcpy), confidence high.**
   `AllocateMotionHistory()`'s `calloc` failure path only logs via `ErrorF` — it doesn't reset
   `pDev->valuator->numMotionEvents` to 0 and the function is `void` (caller,
   `InitValuatorClassDeviceStruct` in `dix/devices.c:1362`, checks nothing). Later,
   `updateMotionHistory()` (`dix/getevents.c:534`) only guards on `numMotionEvents != 0` (still
   true), so it proceeds to `memcpy()` through the NULL `pDev->valuator->motion`. Triggerable by
   plain memory pressure at input-device-init time (e.g. hotplugging a device under OOM) — a
   legitimate low-memory DoS.

2. **`dix/ptrveloc.c:435` (alloc-fail gap, no NULL check at all), confidence high (as a code
   defect); low real-world trigger likelihood.** `InitTrackers()`'s `calloc(ntracker, ...)` for
   `vel->tracker` has zero failure handling; later indexed/written unconditionally via the
   `TRACKER()` macro. All current call sites pass a fixed small `ntracker = 16`
   (`dix/ptrveloc.c:113`), so it needs OOM at a very small allocation to actually trigger, but the
   code path itself has no defense at all.

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
   it's on the normal startup path.

4. **`os/client.c:290-304` (alloc-fail gap, platform-specific), confidence medium.**
   `DetermineClientCmd()`'s `__DragonFly__`/`__FreeBSD__` sysctl branch: `calloc(1, len)` for
   `procargs` is used immediately as the sysctl output buffer and later `strlen()`/`strdup()`'d,
   with no NULL check between allocation and first use. Whether a NULL `procargs` actually reaches
   `strlen`/`strdup` depends on whether the kernel's own `sysctl()` call already faults on a NULL
   buffer pointer first (likely, but not guaranteed on every implementation) — needs OOM either way.

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

1. **`Xext/present/present_notify.c:41-43` + `present_screen.c:117-124` + `present_vblank.c:284-285`
   — UAF, high confidence.** `present_clear_window_notifies()` only nulls `notify->window`, never
   unlinks the notify from its list; `present_destroy_window()` then frees the struct holding that
   list head. A still-linked notify (owned by a pending vblank on a *different* window) later gets
   unlinked via `xorg_list_del()`, writing through prev/next pointers into freed memory. Trigger:
   `PresentPixmap` on window A naming a notify list on window B with a far-future `target_msc`;
   destroy B before it fires; when A's presentation completes, freed memory is corrupted. Single
   client, deterministic, no OOM needed.
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
   repeatable DoS.
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
   operation correctly via a temporary, confirming this macro is the outlier.
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
    backend only.

Areas checked with nothing solid found: `mi/mieq.c`, `miarc.c`, `miwideline.c`, `miexpose.c`,
`mipoly*.c`, `misprite.c`, `miext/damage/` (the known ZDI-CAN-30159/30163 fence UAF is already
fixed), `miext/shadow/`, `miext/sync/`, `Xext/{composite,shm,sync,security,xselinux,saver,record,
xf86bigfont,xv,xfixes,bigreq,xcmisc,xres,namespace,panoramiX,pseudoramiX,dpms,doublebuffer,dri3,
geext}`, most of `Xext/glx/` (context/drawable/vendor lifecycle) and `Xext/xkeyboard/`'s alloc
helpers (`XKBAlloc.c`/`XKBGAlloc.c`/`XKBMAlloc.c`).

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

## Findings: `xf86-video-intel` + `xf86-video-amdgpu` (Constellation)

1. **`xf86-video-intel/src/sna/sna_stream.c:53`, `sna_static_stream_alloc()` — self-overwriting
   realloc, high confidence.** `stream->data = realloc(stream->data, stream->size)` with no NULL
   check; `stream->used` is bumped regardless. Trigger: driver init's 64KB shader-kernel/state
   buffer grows via `sna_static_stream_add()`; on OOM, callers immediately `memcpy`/`memset` through
   the now-NULL `stream->data` — crash during driver init.
2. **`xf86-video-amdgpu/src/amdgpu_kms.c:468`, `transform_region()` — unchecked `malloc`, high
   confidence.** No NULL check before the loop unconditionally writes `rects[nrects].*`. Reachable
   from `amdgpu_sync_scanout_pixmaps()` (TearFree) and `dirty_region()` (rotated/transformed
   outputs) — both normal-use paths, not exotic.
3. **`xf86-video-amdgpu/src/amdgpu_bo_helper.c:198-199`, `amdgpu_pixmap_get_handle()` — unchecked
   calloc, high confidence.** `priv = calloc(...)` stored as the pixmap private, then
   `priv->handle_valid` dereferenced unconditionally on the very next line. On a common path
   (DRI2/DRI3/Present/tiling queries).
4. **`xf86-video-amdgpu/src/drmmode_display.c:2186-2192`, `drmmode_output_create_resources()` —
   two unchecked callocs, high confidence.** `tearfree_prop = calloc(...)` and its `->enums =
   calloc(...)` are both dereferenced/`strcpy`'d unconditionally — inconsistent with the correctly
   NULL-checked `props` calloc three lines earlier in the same function. Runs once per connector at
   startup/hotplug/re-probe.

No confident BO-refcounting UAF in either driver (DRI2/DRI3/Present/glamor BO exchange and
page-flip queues were traced and ref/unref pairing holds). `xf86-video-ati` has a fully separate
`src/` tree from amdgpu/intel (no shared subdirectory) and was not scanned under this task's
"shared code" condition — still open.

## Findings: `xf86-video-nouveau` + `xf86-video-vmware` + `xf86-video-qxl` (Constellation)

1. **nouveau, `src/drmmode_display.c:1438-1441` — unchecked malloc, dangling shadow-FB pointer,
   high confidence.** `drmmode_xf86crtc_resize()` frees `pNv->ShadowPtr` then unconditionally
   reassigns it from `malloc()` with no NULL check; `ShadowFB` stays enabled regardless. Trigger:
   `Option "ShadowFB" "true"` + a RandR resize (`xrandr --fb WxH`) that fails to allocate — the next
   damage refresh (`nv_shadow.c:51-58`) `memcpy`s from `NULL + offset`.
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
   node via `qxl_surface_cache_replace_all()`.
5. **qxl, `src/qxl_surface_ums.c:828-830` — NULL deref on VT re-entry, high confidence.**
   `qxl_surface_cache_replace_all()` derefs `surface->host_image` right after `qxl_surface_create()`,
   which can legitimately return NULL (out of video memory/surfaces) — no NULL check. Trigger: VT
   re-entry when too little device memory remains to recreate all evacuated surfaces.
6. **qxl, `src/qxl_surface_ums.c:774` — unchecked malloc, high confidence.** `evacuated_surface_t
   *evacuated = malloc(...)` used without a NULL check, unlike the careful OOM-retry loops used
   elsewhere in the same file. Trigger: host memory pressure at VT-switch-away time.

## Findings: `xf86-input-libinput` + `xf86-input-wacom` + `xf86-input-synaptics` (Constellation)

1. **libinput, `src/xf86libinput.c:4331`, `update_mode_prop_cb()` — UAF, high confidence.** The
   deferred `QueueWorkProc` callback for tablet-pad mode-group updates derefs `pInfo->private`
   *before* the device-still-alive check that immediately follows it (a `nt_list_for_each_entry`
   walk clearly intended as that liveness check). Trigger: a mode-button press queues this
   callback; the tablet is unplugged (freeing the `InputInfoRec`) before the work queue drains;
   the callback then reads freed memory before its own safety check runs.
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
   `DEVICE_INIT` for any touchpad.
8. **synaptics, `src/synaptics.c:1188`/`1351`/`953-954` — double-free of `open_slots`, traced.**
   `DeviceInitTouch()`'s `malloc()` for `open_slots` happens before the two `hwState` allocations;
   if either fails, the `fail:` label frees `open_slots` without NULLing it, and
   `SynapticsUnInit()`'s later `if (priv->open_slots) free(...)` double-frees it. Trigger: OOM in
   `hwState`/`local_hw_state` alloc during `DEVICE_INIT`, reached via the normal
   `NewInputDeviceRequest` failure-unwind path.
9. **synaptics, `src/eventcomm.c:956-961`, `src/ps2comm.c:382-384`, `src/psmcomm.c:137-139` —
   unchecked proto-data allocs, high confidence.** All three protocol backends (evdev/PS2/PSM)
   store an unchecked `calloc`/alloc result as `priv->proto_data` and immediately dereference it —
   default paths hit on every touchpad `PreInit`/probe.

Nothing solid found in `xf86-input-libinput`'s smaller helpers (`bezier.c`, `draglock.c`,
`util-strings.c`), or beyond the items above in wacom/synaptics.

## Methodology (for whoever scans the next component)

Enumerate every `malloc`/`calloc`/`realloc`/`reallocarray`(-family) call site in the target
directory (excluding `XNFalloc`/`XNFcalloc`-family, which abort internally by design — not a valid
finding), read enough surrounding context per site to confirm there's genuinely no NULL check
anywhere reachable before first use (not just "no check on the same line"). Separately trace
`free()`/`Xfree()` sites in the most complex multi-branch error/cleanup paths for double-free /
use-after-free, prioritizing connection-teardown / client-disconnect code (that's historically
where these cluster). Precision over volume — verify each finding by reading the actual call graph,
not just pattern-matching.
