---
title: "xserver: input_thread Windows enablement via socketpair emulation"
category: active
kind: task
status: "in_progress"
created-by: "Voyager"
created: "2026-09-22T15:45:00Z"
assigned-to: "Voyager"
doc-ref: "—"
slug: xserver/input-thread-mingw-port
---

## Summary

Prototype to make `input_thread` compile on Windows (mingw32) by replacing POSIX `pipe()`/`fcntl()` with Windows socketpair emulation.

## Changes

1. **os/inputthread.c** - Full Windows port:
   - Added `PIPE_FD`/`PIPE_CLOSE`/`PIPE_NONBLOCK`/`PIPE_MAKE_INHERIT` macros for platform abstraction
   - Socketpair emulation via `WSASocket` + loopback connect (bind/listen/accept on 127.0.0.1:0)
   - Non-blocking via `ioctlsocket(FIONBIO)` instead of `fcntl(O_NONBLOCK)`
   - Close-on-exec via `SetHandleInformation(HANDLE_FLAG_INHERIT)` instead of `fcntl(FD_CLOEXEC)`
   - `send`/`recv` instead of `write`/`read`
   - Signal masking no-op on Windows (no `sigfillset`/`pthread_sigmask`)
   - `closesocket` instead of `close`

2. **include/meson.build** - Removed Windows auto-disable:
   - Deleted block that forced `enable_input_thread = false` for Windows + `input_thread=auto`
   - Now `input_thread=true` enables it on Windows too (requires `PTHREAD_MUTEX_RECURSIVE`)

## Behavior on Windows

- Thread starts, creates internal socketpairs for wakeup/hotplug
- No real input devices registered (no `/dev/input/event*` on Windows)
- Thread polls its own socketpair, effectively idle
- Same code path as Linux, just no devices to process

## Branch

`wip/input-thread-mingw-port` on X11Libre/xserver

## Next Steps

- Run GitHub CI (mingw32-ubuntu + cygwin lanes) to validate compile
- Test runtime behavior on Windows host
