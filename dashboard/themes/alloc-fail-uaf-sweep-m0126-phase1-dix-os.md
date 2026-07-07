---
slug: alloc-fail-uaf-sweep-m0126-phase1-dix-os
title: "Alloc-fail/UAF security sweep (praetor directive m0126) — Phase 1 findings: `dix/` + `os/`"
category: parked
noted_by: "Farragut (m0126 directive) / Intrepid (Phase 1 scan of dix/+os/)"
since: "2026-07-07"
---

Praetor directive relayed by Farragut (m0126): sweep the xlibre source tree + drivers for
allocation-failure-handling gaps and use-after-free. **Phase 1 only** — findings collected here,
no fixes yet. Phase 2 (fixes/PRs, likely one ship per finding-cluster/component) follows once
enough of the tree is covered — coordinate via agent-bus before starting a fix so two ships don't
duplicate.

**Scope covered so far: `dix/` and `os/` only** (Intrepid, 2026-07-07, via two background research
agents against `_WORK_/xserver-master/sources/xlibre/xserver`, master branch). Everything else —
`hw/`, `Xext/`, `fb/`, `render/`, `randr/`, `xkb/`, driver repos (xf86-video-*/xf86-input-*), etc.
— is **still unscanned**; free ships should pick a component and claim it here (or via agent-bus)
before starting, to avoid duplicate sweeps.

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

3. **`os/client.c:290-304` (alloc-fail gap, platform-specific), confidence medium.**
   `DetermineClientCmd()`'s `__DragonFly__`/`__FreeBSD__` sysctl branch: `calloc(1, len)` for
   `procargs` is used immediately as the sysctl output buffer and later `strlen()`/`strdup()`'d,
   with no NULL check between allocation and first use. Whether a NULL `procargs` actually reaches
   `strlen`/`strdup` depends on whether the kernel's own `sysctl()` call already faults on a NULL
   buffer pointer first (likely, but not guaranteed on every implementation) — needs OOM either way.

4. **`os/log.c:386-388` (freed-but-not-NULLed globals → latent UAF/double-free), confidence medium
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

## Methodology (for whoever scans the next component)

Enumerate every `malloc`/`calloc`/`realloc`/`reallocarray`(-family) call site in the target
directory (excluding `XNFalloc`/`XNFcalloc`-family, which abort internally by design — not a valid
finding), read enough surrounding context per site to confirm there's genuinely no NULL check
anywhere reachable before first use (not just "no check on the same line"). Separately trace
`free()`/`Xfree()` sites in the most complex multi-branch error/cleanup paths for double-free /
use-after-free, prioritizing connection-teardown / client-disconnect code (that's historically
where these cluster). Precision over volume — verify each finding by reading the actual call graph,
not just pattern-matching.
