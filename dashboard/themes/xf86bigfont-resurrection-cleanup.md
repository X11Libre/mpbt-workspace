---
slug: xf86bigfont-resurrection-cleanup
title: "`xf86bigfont` resurrection & cleanup"
category: active
status: "Step 1 **done** — builds on all lanes again (#3202 **merged**: sysmacros + mingw fixes). #3205 **merged**: meson default-**off** restored + bigfont enabled only on the CI lanes (praetor: \"meson defaults nicht anfassen\"). #3206 backports both compile fixes to **release/25.2** (25.1/25.0 = older bigfont.c, N/A). #3203 (dix ARRAY_SIZE guard) **merged**. #3201 (pagesize/CSRG cleanup) **merged** (rebased, all bigfont lanes green)."
doc_ref: "`BIGFONT.md` (source); PRs #3202 + #3205 (merged: CI builds bigfont on all lanes, default off), #3203 (dix ARRAY_SIZE guard, merged), #3201 (pagesize/CSRG, merged); branch `xlibre/bigfont-consolidate-cleanup` (ResetProc drop, no commit yet)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

`Xext/xf86bigfont/` shares font-metrics arrays with local clients via SysV shared memory
(and compresses them for remote clients). It has been **`option('xf86bigfont', value: false)`
by default**, so — until PR #3202 — **no build, and no CI lane, ever compiled it**. Turning it on
in CI immediately surfaced that the code has bit-rotted on every non-Linux platform.

## Step 1 — make it build cleanly again (done)

#3202 **merged** (sysmacros + mingw fixes) — bigfont now builds on all lanes. The sysmacros removal
also fixed the solaris `ARRAY_SIZE` clash (that header was the source). #3202 also flipped the meson
default on; **#3205** restores it to **off** and instead enables bigfont only on the CI lanes (per
maintainer: don't change meson defaults). `dix.h` `ARRAY_SIZE` guarded defensively by #3203.

Enabling it by default (PR #3202, `xlibre/ci-build-bigfont`) is what exposes the breakage; the run
is green on Linux (ubuntu/rhel/alpine/gentoo/arch, 71 jobs) and **red on 7 lanes**:

| Lanes | Error | Root cause | Fix | Backport? |
|-------|-------|-----------|-----|-----------|
| macos, freebsd, dragonfly, netbsd, openbsd | `xf86bigfont.c:49: 'sys/sysmacros.h' file not found` | Linux/glibc-only header, unguarded; **not actually used** (no `major()/minor()/makedev()`) | **drop the `#include`** | ✅ compile-break on release-CI'd BSD/macOS lanes → backport candidate |
| solaris | `include/dix.h:68: "ARRAY_SIZE" redefined` | it was `<sys/sysmacros.h>` (Solaris defines `ARRAY_SIZE` there) — **fixed by the same sysmacros removal**. `dix.h` also guarded defensively (#3203) | ✅ done | no release Solaris CI → n/a |
| mingw32 | `geteuid`/`getegid` implicit decl (`xf86bigfont.c:281/282`) + `stuff_flags` set-but-unused (`:333`) | Windows has no real euid/gid; the calls are **not** under `CONFIG_MITSHM` | guard the euid/gid use (Win = stub) + fix the unused var | n/a (mingw not a release lane) |

Which platforms were already CI-supported in releases (→ backport candidates for their fixes):
confirm per release line via the release `build-xserver.yml` matrices; the BSD/macOS `sysmacros`
break is the clearest compile-break candidate.

## Order of work
1. **sysmacros `#include` drop** — trivial, fixes 5 lanes at once; start here. Backport with a
   compile-break justification to the release lines that build those platforms.
2. **solaris `ARRAY_SIZE`** — `#ifndef` guard in `include/dix.h`.
3. **mingw** — guard `geteuid`/`getegid` (Windows stub) + the unused-var.
4. Then the extension builds everywhere and #3202 can go green.

## Related, already-open cleanups (separate PRs)
- **#3201** `xlibre/bigfont-drop-pagesize` — drop the redundant SHM page-rounding + `pagesize`
  (removes the only `CSRG_BASED` user in the file); `pagesize==0` sentinel → `bool shmSupported`.
- **`xlibre/bigfont-consolidate-cleanup`** (branch created, **commit not yet authored** — pending
  maintainer OK on the approach) — drop the redundant `XF86BigfontResetProc` (pure `ExtensionEntry` callback, redundant with `FreeAllResources` on graceful exit and `AbortServer→XF86BigfontCleanup` on abort) → pass `NULL` reset proc. Do this **after** the build resurrection so it's CI-covered.

**Competing proposal in flight:** praetor also wants a draft PR to remove `xf86bigfont` entirely
(see theme `propose-removing-xf86bigfont-extension-entirely`) — the two are deliberately parallel
options to put before the community, not a contradiction to resolve here.

## Later / open design questions (Parkplatz)
- **Hard-wired call in dix `CloseFont()`** (`dix/dixfonts.c:539`, `#ifdef XF86BIGFONT` →
  `XF86BigfontFreeFontShm`): a direct dix→extension dependency. Consider decoupling (per-font
  free-callback / registration) so dix doesn't hard-reference the extension.
- **Does part of bigfont belong in dix?** The shm/font-metrics-sharing machinery is arguably
  dix-level; the *extension* could be reduced to the pure protocol/wire interface. Bigger redesign.

## External call surface (for reference, verified)
- init: `mi/miinitext.c` → `XFree86BigfontExtensionInit` (indirect, init table)
- per-font free: `dix/dixfonts.c:539` `CloseFont()` → `XF86BigfontFreeFontShm` (**direct**, `#ifdef XF86BIGFONT`)
- abort: `os/utils.c:1492` `AbortServer()` → `XF86BigfontCleanup` (**direct**, `#ifdef XF86BIGFONT`)
- reset: `XF86BigfontResetProc` (indirect `ExtensionEntry` callback; **no external refs** → safely removable)
- requests: `ProcXF86BigfontDispatch` (indirect, extension request table)
