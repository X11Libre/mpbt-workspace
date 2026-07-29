---
name: ci-platform
description: How the XLibre xserver CI is wired — per-platform lanes, content-addressed deps images (build-if-missing), the hand-rolled GNU/Hurd QEMU boot, the RHEL/AlmaLinux lane, per-lane -Dwerror status, and the scoped NetBSD pkg mirror. Use when debugging a red CI lane, adding a platform, or reasoning about why a lane was skipped.
---

# CI platform lanes (Docker images + VM builds)

The `Build X servers` workflow (`.github/workflows/build-xserver.yml`) fans out one job per
platform. Full detail: **`reference.md`** in this skill's directory (moved out of AGENTS.md).

Run commands from the workspace root (`/home/nekrad/src/xorg/mpbt-workspace`).

## Mental model

- **Content-addressed deps images (build-if-missing).** `gentoo-deps-image` / `ubuntu-deps-image`
  tags are a sha256 of their build inputs; the job `docker manifest inspect`s and only rebuilds when
  the exact tag is missing. `:latest` moves only on master. The per-commit SDK builds `FROM` the
  content-hashed ubuntu base, so a WIP branch uses exactly the deps it defines (no staleness).
- **abi-gated ubuntu/SDK chain:** `ubuntu-deps-image` / `build-sdk-image` / `drivers-build-ubuntu`
  run only on `abi_changed || tag` — a workflow-only PR skips them (gentoo always runs).
- **GNU/Hurd has no vmactions VM — it's a hand-rolled QEMU boot** (`xserver-build-hurd` →
  `.github/scripts/hurd/run-vm-build.sh`). Gotchas: `-M q35` + `ich9-ahci` AHCI (not i440fx IDE);
  gnumach is single-CPU (`-smp` forbidden); add a serial console to `grub.cfg` for `-nographic`;
  `sudo chmod 666 /dev/kvm` (fall back to `-accel tcg`); retry boot ≤3×. Builds Xvfb/Xnest/Xorg/
  Xephyr/GLX (`-Dxvfb -Dxnest -Dxorg -Dxephyr -Dglx`, dri*/glamor/xfbdev/udev/logind off). DRI and
  glamor are fundamentally non-buildable on Hurd (no DRM kernel interface); the one real port task
  is a Hurd kdrive backend for `xfbdev`.
- **RHEL/AlmaLinux lane** (`xserver-build-rhel`): `almalinux:9/10`, EPEL+CRB enabled; do **not**
  list `xorg-x11-font-utils` (not a build dep, aborts `dnf`); RHEL 10 gcc 14 needs the
  `set_sun_path` format-truncation fix for `-Dwerror=true`.
- **`-Dwerror=true` per lane:** on for `ubuntu*`, `rhel`, `solaris`, `gentoo`, `openbsd`; **`alpine`
  stays off** (musl/libbsd `#warning` under `-Werror=cpp` — toolchain quirk, not our bug).
- **NetBSD scoped mirror** (`netbsd-pkgsrc-mirror` release in `X11Libre/xserver`) dodges
  ftp.netbsd.org flakes; `install-pkg.sh` tries the mirror first, falls back to official. Refresh via
  `.github/workflows/netbsd-pkg-mirror.yml` (`workflow_dispatch`). Never hardcode the quarter date in
  the `<rel>/All` 302 redirect — `curl -L` follows it.

## When debugging a red lane

1. Identify the lane + failure class (build/link, configure/meson, test-phase/XTS).
2. For a WIP branch that "shouldn't have rebuilt deps": check whether the change actually altered the
   deps-image inputs (else the cached content-hashed image is reused — a few-second check).
3. For Hurd: confirm the QEMU attach flags and serial console before assuming a silent hang.
4. For NetBSD: confirm the mirror release is populated (one `workflow_dispatch`) before trusting the
   mirror-first path.
