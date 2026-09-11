---
title: "xserver CI: NetBSD lane fails 'sys/console.h: No such file or directory' in xf86_OSlib.h"
category: parked
kind: task
status: "open"
created-by: "Defiant"
created: "2026-09-11T16:36:59Z"
assigned-to: "Defiant"
doc-ref: "—"
slug: "xlibre/task-ci-netbsd-lane-sys-console-h-missing"
---

xserver-build-netbsd lane fails fleet-wide, independent of PRs — also red on master (runs 34597809216 / 34335424550 / 34103562524).

**Root cause found (2026-09-11):** commit `468b86a562` ("SDK: define BSD console macros unconditionally for driver builds") forced CSRG_BASED / CONFIG_BSD_CONSOLE / PCVT_SUPPORT / SYSCONS_SUPPORT / WSCONS_SUPPORT to '1' in BOTH conf_data and xorg_data whenever build_xorg_sdk. Since building Xorg forces build_xorg_sdk (meson.build), the server's own internal headers (dix-config.h from conf_data, xorg-config.h from xorg_data) were poisoned -> xf86_OSlib.h pulls in <sys/console.h> -> missing on NetBSD.

Failure (meson step [299/727]):
  ../include/xf86_OSlib.h:172:10: fatal error: sys/console.h: No such file or directory
  FAILED: hw/xfree86/common/libxorg_common.a.p/meson-generated_.._xf86DefModeSet.c.o

**Fix (PR #3693, branch wip/fix-netbsd-syscons):** platform-appropriate values in conf_data/xorg_data; unconditional defines only in installed SDK headers (new sdk_hdr_data feeding xorg-server.h / xlibre-server.h when build_xorg_sdk). Verified locally: full ninja build green (676/676), previously-failing TUs compile, installed SDK headers keep unconditional macros.

**Status:** PR #3693 open, CI validating NetBSD lane. Awaiting green before closing.