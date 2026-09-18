---
slug: xlibre/task-netbsd-ci-fix-pr-3700
title: "NetBSD CI build failure fix (PR #3700)"
status: in-progress
---

## Context
NetBSD CI job failing in GitHub Actions run [#35108104256](https://github.com/X11Libre/xserver/actions/runs/35108104256) - all 3 retry attempts exhausted.

## Root Cause
The failed CI run was at commit `3615902e7d` which predates several NetBSD fixes already present in the `fix/netbsd-ci-ssh-fix` branch but not yet merged to master:
- `c04a7a2a2e`: Remove ubuntu-fetch-pkg dependency from NetBSD job
- `c5746d1277`: Upgrade vmactions/netbsd-vm to v1.5.0
- `51bba491c9`: Fix console_syscons.c build on NetBSD
- `d60d816ea2`: Conditional PCVT/SYSCONS macros for FreeBSD/DragonFly only
- `46ab8082cc`: Guard sys/console.h include for non-NetBSD/OpenBSD

## Fix Applied (PR #3700)
Created branch `fix/netbsd-ci-build-failures` with:
1. **CI Workflow** (.github/workflows/build-xserver.yml):
   - Removed `needs: ubuntu-fetch-pkg` and `ubuntu-pkg-cache` from NetBSD job
   - Upgraded `vmactions/netbsd-vm` from v1.2.3 → v1.5.0 (fixes Node.js 20 deprecation)
   - Added `sync: rsync` for reliable file transfer

2. **meson.build**: Only define PCVT_SUPPORT/SYSCONS_SUPPORT for FreeBSD/DragonFlyBSD

3. **xf86_OSlib.h**: Guard `#include <sys/console.h>` with `#if !defined(__NetBSD__) && !defined(__OpenBSD__)`

4. **console_syscons.c**: Wrap entire implementation in `#if defined(SYSCONS_SUPPORT) && (defined(__FreeBSD__) || defined(__DragonFly__))`

## Status
PR #3700 created: https://github.com/X11Libre/xserver/pull/3700
Awaiting CI validation on the PR.
