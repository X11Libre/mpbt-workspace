---
title: "CI platform lanes — Docker images + VM builds"
order: 100
---

## CI platform lanes — Docker images + VM builds

The `Build X servers` workflow (`.github/workflows/build-xserver.yml`) fans out one
job per platform. Two non-obvious mechanisms:

- **Content-addressed deps images (build-if-missing).** The gentoo and ubuntu base
  images are built by in-pipeline jobs (`gentoo-deps-image`, `ubuntu-deps-image`)
  whose **image tag is a sha256 of the image's build inputs** (Dockerfile + the
  install scripts + `conf.sh`/`util.sh`); the job does a `docker manifest inspect`
  and **only builds when that exact tag is missing**, else reuses (a few-second
  check vs a ~15–22 min rebuild). `:latest` is moved only by master. The per-commit
  SDK (`build-sdk-image`) builds `FROM` the content-hashed ubuntu base via the SDK
  Dockerfile's `ARG BASE` + a `--build-arg BASE=…/xserver-ubuntu-build:<hash>`, so a
  WIP branch's SDK is built on exactly the deps that branch defines (no staleness).
  This replaced the standalone `gentoo-image.yml`/`ubuntu-deps-image.yml`/
  `sdk-image.yml` (PR #3180), which rebuilt per-branch and let WIP branches consume a
  stale master `:latest`. **Gotcha:** `ubuntu-deps-image`/`build-sdk-image`/
  `drivers-build-ubuntu` are **abi-gated** (`if: abi_changed || tag`), so a
  workflow-only PR **skips** them — the ubuntu/SDK chain is exercised only on a real
  ABI-changing commit (gentoo is *not* abi-gated and always runs).

- **GNU/Hurd has no vmactions VM — it's a hand-rolled QEMU boot** (`xserver-build-hurd`
  → `.github/scripts/hurd/run-vm-build.sh`, PR #3179). Hard-won boot recipe:
  - The amd64 Hurd image uses **rumpdisk** for SATA, so the disk MUST be attached via
    **`-M q35` + an `ich9-ahci` AHCI controller** (`-device ich9-ahci` + `ide-hd
    bus=ahci.0`). The default i440fx IDE disk yields an `ext2fs` I/O error and never
    boots.
  - **gnumach boots single-CPU only** — no `-smp`.
  - GRUB + gnumach log to **VGA only**; patch `grub.cfg` to add a **serial console**
    (`serial`/`terminal_*` + `console=com0` on the multiboot line) so the boot is
    visible under `-nographic` (otherwise it looks like a silent hang).
  - **`/dev/kvm` exists on GH runners but isn't accessible to the runner user** —
    `sudo chmod 666 /dev/kvm` (fall back to `-accel tcg` if unavailable).
  - **VM boot flakes transiently** → retry the boot up to 3×.
  - In-VM (`run-xserver-build.sh`): the toolchain install (git/meson/ninja/pkg-config)
    is **fatal**, the X protocol libs are **best-effort**. The lane now **fatally
    builds every server that compiles on Hurd** in one meson run —
    `-Dxvfb -Dxnest -Dxorg -Dxephyr -Dglx` — with `dri*`/`glamor`/`xfbdev`/`udev`/
    `logind` off (PR #3193). ~12–13 min total.
  - **What builds on Hurd today (final: PR #3179 added the lane, #3193 made it
    build all five servers).** The gaps below were surfaced one at a time by
    disabling the previous blocker; the review of #3193 (stefan11111) then
    established that glx + Xephyr build too:
    | server / flag | result |
    |---|---|
    | Xvfb, Xnest | ✅ build |
    | `-Dxorg` (xfree86) | ✅ builds — `Linking target hw/xfree86/Xorg` (unaccelerated) |
    | `-Dxephyr` | ✅ builds — but needs `libxcb-xv0-dev` (else meson setup errors `Dependency "xcb-xv" not found`); it runs as an X client over XCB, not the kdrive linux VT/input path |
    | `-Dglx` | ✅ builds **without libdrm** (software/indirect GLX) |
    | `-Ddri1/2/3` | ❌ `hw/xfree86/dri/dri.c` → libdrm's `<drm.h>` pulls a nonexistent `mach/x86_64/ioccom.h` — Hurd has no DRM kernel interface |
    | `-Dglamor` | ❌ `glamor/glamor_egl.c` → `DRM_FORMAT_MOD_INVALID` undeclared + needs GBM (GBM needs DRM) — confirmed non-buildable on Hurd |
    | `-Dxfbdev` (kdrive fbdev) | ❌ builds `hw/kdrive/linux/linux.c` → needs Linux VTs `<linux/vt.h>` — would need a dedicated **Hurd kdrive backend** |

    Takeaways: the **xfree86 Xorg server + Xephyr + GLX build cleanly on GNU/Hurd**
    (unaccelerated). The remaining blockers are **fundamental, not port bugs**: DRI
    and glamor need a DRM kernel interface Hurd lacks. The one **real** open port
    task is a **Hurd kdrive backend** for `xfbdev` (the Linux-VT dependency). Note
    `libdrm-dev` *does* exist on Hurd (`debian-ports`, `2.4.107+hurd`) — installing
    it isn't the DRI blocker; the missing Mach ioctl header is.

- **RHEL/AlmaLinux lane** (`xserver-build-rhel`, PR #3172). Matrix `rhelver: ['9','10']` on
  `almalinux:9`/`:10` containers — AlmaLinux is an ABI-identical RHEL rebuild and stands in for
  RHEL because the real UBI images can't enable **CRB** without an entitlement on public runners.
  `install-pkg.sh` enables **EPEL + CRB** (most X `-devel` packages live in CRB), then `dnf`-installs
  the deps. Two gotchas hit while adding it:
  - **`xorg-x11-font-utils` does not exist on RHEL 9/10** (dropped, not in EPEL/CRB) — and it is
    **not** a build dep (`meson.build` uses `dependency('fontutil', required: false)` with a
    `$datadir/fonts/X11` fallback). Don't list it; it just aborts `dnf`.
  - **RHEL 10's gcc 14 raised `-Werror=format-truncation`** in `os/Xtranssock.c` `set_sun_path()` —
    a false positive (a manual length pre-check already prevented truncation, but GCC couldn't
    connect it to the `snprintf` bound). Fixed at source by checking the `snprintf` return value
    instead (#3176, `set_sun_path`), so the lane runs **`-Dwerror=true`** like the other Linux jobs.

- **`-Dwerror=true` status per lane** (probe June 2026). Lanes build clean under werror and have it
  **on**: `ubuntu*`, `rhel` (after #3176), and — after **#3196** — **`solaris`/`gentoo`/`openbsd`**.
  That PR fixed the two real warnings the probe surfaced and flipped those three lanes:
  - **`gentoo`** — `test/bigreq/request-length.c` ignored `write()`'s return (`-Werror=unused-result`);
    now checked. (Its *old* `werror=false` reason, format-truncation in `set_sun_path`, was already
    gone — fixed by #3176.)
  - **`openbsd`** — `os/client.c` declared the `/proc` vars `path`/`totsize`/`fd` on OpenBSD too,
    where the `kvm_getprocs` branch doesn't use them (clang `-Wunused-variable`); fixed by excluding
    `__OpenBSD__` from the declaration guard.
  - **`solaris`** — was already clean; just flipped.
- **`alpine` is the one lane that stays `-Dwerror=false`, and it's *not* our bug to fix.** On musl,
  libbsd's `<bsd/sys/cdefs.h>` pulls the system `<sys/cdefs.h>`, which emits a `#warning`
  (*"usage of non-standard #include <sys/cdefs.h> is deprecated"*) that `-Werror` (`-Werror=cpp`)
  turns fatal in **every** TU that uses libbsd (miinitext, gtf, present, vblank, …). It's a
  musl/libbsd toolchain quirk, unfixable in-tree without suppressing the whole `cpp` warning class —
  so the lane stays werror-off, documented inline in `build-xserver.yml`.

- **NetBSD lane has a scoped GitHub-hosted dependency mirror (to dodge ftp/cdn.netbsd.org flakes).**
  `xserver-build-netbsd` used to install its deps straight from the official NetBSD mirrors, which
  flake intermittently (`pkg_add: ... Undefined error: 0`, all 3 internal retries exhausted — the
  same BSD/Solaris VM-flake class as the vmactions jobs; hit on **PR #3225**, 2026-07-03, reddening
  an Ubuntu-only diff). Fix (**PR #3243**, opened not merged): a **scoped** mirror of *just* what
  this job needs — the pkgin dependency closure of the build's package list + the 5 X11 OS-release
  binary sets, ≈230 MB (vs ~65 GB full pkgsrc) — hosted as assets of a **stable GitHub Release
  `netbsd-pkgsrc-mirror`** in `X11Libre/xserver`. `install-pkg.sh` now tries the mirror **first**
  and falls back to the official mirrors (soft fallback, not a hard cutover). The package list +
  release/arch + all URLs live in one shared **`.github/scripts/netbsd/mirror-conf.sh`** sourced by
  both `install-pkg.sh` and the sync. **To refresh/poke the mirror:** run the weekly
  **`.github/workflows/netbsd-pkg-mirror.yml`** (`Refresh NetBSD pkg mirror`, also
  `workflow_dispatch`) — it boots the *same* `vmactions/netbsd-vm` image the build lane uses, drives
  the real `pkgin -d install` (download-only, cache = `/var/db/pkgin/cache`) to get the
  authoritative closure (no hand-rolled resolver), builds a **trimmed `pkg_summary.gz`** (a strict
  *subset* of the official summary, so `FILE_SIZE`/metadata stay byte-consistent — pkgin verifies
  size, there's no checksum field), and `gh release upload --clobber`s + prunes stale assets
  (`publish-mirror.sh`). **Gotchas / assumptions:** (1) the mirror release must be populated by one
  `workflow_dispatch` run before the mirror-first path finds anything (until then the lane just uses
  the official fallback); (2) the closure matches the build only because sync-VM-image ==
  build-VM-image (both `netbsd-vm@v1.2.3` release `10.1`); (3) unverified without a live VM: whether
  pkgin's libfetch follows GitHub's 302 release-asset redirect for `pkg_summary.gz`/`.tgz` (the
  fallback exists precisely to cover this if it doesn't); (4) `<rel>/All` 302-redirects to a dated
  quarterly (`10.0_2026Q1/All`) that moves over time — the sync follows it with `curl -L`, never
  hardcode the date. Debugging the awk trim: reading the keep-list must happen under the default
  `RS="\n"` *before* switching to paragraph mode `RS=""`, else the whole keep-list slurps into one
  key and nothing matches.
