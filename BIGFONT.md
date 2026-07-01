# BIGFONT.md — resurrecting & cleaning up the XF86-BigFont extension

`Xext/xf86bigfont/` shares font-metrics arrays with local clients via SysV shared memory
(and compresses them for remote clients). It has been **`option('xf86bigfont', value: false)`
by default**, so — until PR #3202 — **no build, and no CI lane, ever compiled it**. Turning it on
in CI immediately surfaced that the code has bit-rotted on every non-Linux platform.

## Step 1 — make it build cleanly again (in progress)

Enabling it by default (PR #3202, `xlibre/ci-build-bigfont`) is what exposes the breakage; the run
is green on Linux (ubuntu/rhel/alpine/gentoo/arch, 71 jobs) and **red on 7 lanes**:

| Lanes | Error | Root cause | Fix | Backport? |
|-------|-------|-----------|-----|-----------|
| macos, freebsd, dragonfly, netbsd, openbsd | `xf86bigfont.c:49: 'sys/sysmacros.h' file not found` | Linux/glibc-only header, unguarded; **not actually used** (no `major()/minor()/makedev()`) | **drop the `#include`** | ✅ compile-break on release-CI'd BSD/macOS lanes → backport candidate |
| solaris | `include/dix.h:68: "ARRAY_SIZE" redefined [-Werror]` | a Solaris system header (pulled in via bigfont's `sys/*` includes) already defines `ARRAY_SIZE`; `dix.h` defines it unconditionally | guard `dix.h`'s `ARRAY_SIZE` with `#ifndef` (core-header touch) | evaluate per release |
| mingw32 | `geteuid`/`getegid` implicit decl (`xf86bigfont.c:281/282`) + `stuff_flags` set-but-unused (`:333`) | Windows has no real euid/gid; the calls are **not** under `CONFIG_MITSHM` | guard the euid/gid use (Win = stub) + fix the unused var | n/a (mingw not a release lane) |

**Which platforms were already CI-supported in releases** (→ backport candidates for their fixes):
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
- **`xlibre/bigfont-consolidate-cleanup`** (ready, not pushed) — drop the redundant
  `XF86BigfontResetProc` (pure `ExtensionEntry` callback, redundant with `FreeAllResources` on
  graceful exit and `AbortServer→XF86BigfontCleanup` on abort) → pass `NULL` reset proc. Do this
  **after** the build resurrection so it's CI-covered.

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
