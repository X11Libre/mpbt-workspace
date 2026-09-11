Title: "xserver CI: NetBSD lane fails 'sys/console.h: No such file or directory' in xf86_OSlib.h"
Category: parked
Kind: task
Status: "open"
Created-By: "Defiant"
Created: "2026-09-11T16:36:59Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/xlibre/task-ci-netbsd-lane-sys-console-h-missing

xserver-build-netbsd lane fails fleet-wide, independent of PRs — also red on master (runs 34597809216 / 34335424550 / 34103562524) and on PR #3692 run 34618298573 (job 103325732530).

Failure: at meson step [299/727] compiling hw/xfree86/common/xf86DefModeSet.c / xf86Configure.c:
  ../include/xf86_OSlib.h:172:10: fatal error: sys/console.h: No such file or directory
  FAILED: hw/xfree86/common/libxorg_common.a.p/meson-generated_.._xf86DefModeSet.c.o
  ninja: build stopped: subcommand failed.

Root cause hypothesis: the NetBSD VM package set (vmactions/netbsd-vm@v1.2.3) no longer provides sys/console.h (provided by e.g. a kernel/console header package), or xf86_OSlib.h unconditionally includes it where it should be guarded. Needs investigation of the NetBSD deps setup (.github/workflows/build-xserver.yml, netbsd job) and/or the include guard.

Not caused by PR #3692 (cygwin CI change) nor any cygwin work — pure NetBSD infra/code issue.
