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

## Governance Decision (per Enterprise)

**Default remains OFF on Windows** - auto-disable in meson.build preserved. Opt-in only via `-Dinput_thread=true`.

No consumer currently needs Windows input thread. Prototype is for CI/compile-proof only.

## Changes

1. **os/inputthread.c** - Full Windows port (compile-proof):
   - Added `PIPE_FD`/`PIPE_CLOSE`/`PIPE_NONBLOCK`/`PIPE_MAKE_INHERIT` macros for platform abstraction
   - Socketpair emulation via `WSASocket` + loopback connect (bind/listen/accept on 127.0.0.1:0)
   - Non-blocking via `ioctlsocket(FIONBIO)` instead of `fcntl(O_NONBLOCK)`
   - Close-on-exec via `SetHandleInformation(HANDLE_FLAG_INHERIT)` instead of `fcntl(FD_CLOEXEC)`
   - `send`/`recv` instead of `write`/`read`
   - Signal masking no-op on Windows (no `sigfillset`/`pthread_sigmask`)
   - `closesocket` instead of `close`

2. **include/meson.build** - Windows auto-disable preserved:
   - `input_thread=auto` -> false on Windows
   - Explicit `-Dinput_thread=true` enables it (requires `PTHREAD_MUTEX_RECURSIVE`)

## Behavior on Windows

- Thread starts, creates internal socketpairs for wakeup/hotplug
- No real input devices registered (no `/dev/input/event*` on Windows)
- Thread polls its own socketpair, effectively idle
- Same code path as Linux, just no devices to process

## Outstanding Issues

- Runtime: thread is "useless" on native Windows (Turney's point stands - no /dev/input, window events tied to creating thread)
- Shared core `os/inputthread.c` change needs proper review/PR before merge consideration
- No concrete consumer for Windows input thread identified

## Branch

`wip/input-thread-mingw-port` on X11Libre/xserver

## CI Status

GitHub Actions running - validates opt-in compile on mingw32-ubuntu + cygwin
