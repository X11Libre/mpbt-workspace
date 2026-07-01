TODO
====

- [ ] set up git-autopick (xorg backports)
- [ ] add pkg-config checks for OS-installed packages
- [ ] github CI: check apt-caching: the netbsd job still downloading lots of deb packages
- [ ] github CI: check apt-caching: the dragonfly job still downloading lots of deb packages
- [ ] github CI: check apt-caching: the freebsd job still downloading lots of deb packages
- [ ] github CI: alpine job runs in container --> doesn't need to wait for ubuntu-pkg job
- [ ] github CI: PRs always trigger two duplicate pipelines (even when pushing into existing one)
- [ ] github CI: give piglit a per-test timeout on the `xephyr-glamor / XTS` run (`test/scripts/xephyr-glamor-piglit.sh` -> `run-piglit.sh` passes no `-t`/timeout flag to piglit itself); right now a single wedged XTS subtest blocks silently until the whole-suite meson `timeout: 1200` in `test/meson.build` kills it, with zero progress output to identify which subtest hung. A real per-test timeout would fail fast with a subtest name instead. (found 2026-07-01 investigating a 64min/3-retries-exhausted CI hang on PR #3203, see DASHBOARD.md)
- [ ] add script for setting up git object sharing between the xserver repos
- [ ] add automatic build of a cygwin repo
- [ ] check whether it's possible to run a real Xserver (xfree86 or Xfbdev) within the github CI.
- [ ] add agent helper scripts for github api access (eg log retrieval) and authorize them (no more manual confirmation)

future topics:
--------------

- [ ] fd-passing redesign — branch `submit/recv-fds` (X11Libre/xserver), parked, build-verified,
      NOT PR'd. Two commits:
        1. `os: collect passed file descriptors into the client struct up front` — push model:
           ReadRequestFromClient() drains all of a request's SCM_RIGHTS fds into
           `client->recv_fd_list[MAX_CLIENT_RECV_FD]` at read time; Dispatch() closes the ones the
           handler didn't keep. Replaces the old pull model (SetReqFds + per-fd ReadFdFromClient).
           Keeps `ReadFdFromClient()` (_X_EXPORT) and the `req_fds` field as an ABI shim — the
           nvidia blob (470/550/570) imports ReadFdFromClient and pokes req_fds directly. Also fixes
           an fd==0 bug (`>0` vs `>=0`, fd 0 is valid).
        2. `dix: add X_REQUEST_FDS() and convert dri3/shm handlers` — declarative macro
           `X_REQUEST_FDS(name...)` (variadic, named fd vars, early, one line) + `X_REQUEST_FDS_ARRAY`
           + `X_REQUEST_FD_KEEP(fd)` (mark ownership transferred). Default = Dispatch closes → error
           paths leak-free for free.
      Why parked / why push model: the clean single-point macro is inherently a push-model feature —
      on the old pull model, fetching early either leaks an fd on a late validation error or delivers
      a stale fd to the next request (master's SetReqFds-early + fetch-late is deliberate). Enables
      the future goal of frame/packet/memblock transports (read a request fully into a queue before
      dispatch). To resume: decide whether to PR the redesign (ABI-review the shim) and, once in,
      the macro internals swap cleanly from recv_fd_list to whatever the transport provides.

reviews:
--------

