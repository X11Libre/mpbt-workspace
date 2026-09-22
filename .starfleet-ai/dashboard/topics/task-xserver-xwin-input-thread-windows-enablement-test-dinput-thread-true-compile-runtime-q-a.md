Title: "xserver: xwin input_thread Windows enablement — test -Dinput_thread=true (compile + runtime Q/A)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-22T10:27:31Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-xserver-xwin-input-thread-windows-enablement-test-dinput-thread-true-compile-runtime-q-a

Voyager analysis verified: input_thread=auto default; windows+auto forced false (include/meson.build:62-63); true+no PTHREAD_MUTEX_RECURSIVE = hard error; disabled on Windows since 2016 commit 246b729df8 (Jon Turney); xwin ddxInputThreadInit already #if INPUTTHREAD guarded. Linux/glibc already builds INPUTTHREAD=1. Voyager in progress: separate worktree/branch + GitHub CI test (mingw32-ubuntu + cygwin) with -Dinput_thread=true, runtime Q/A on Windows host.
