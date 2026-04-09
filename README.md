XLibre MPBT workspace
======================

This is an [MPBT](https://github.com/metux/mpbt) workspace for building
[XLibre](https://github.com/X11Libre/) Xserver and drivers all at once.

Warning: it's still an early work-in-progress.

howto:
------

* install MPBT: `go install github.com/metux/mpbt/cmd/mpbt-builder@latest`
* just fetch git repos: `./run-fetch-[...]`
* full build: `./run-build-[...]`

Release lines:
--------------

Since we have multiple release lines (25.0.x, 25.1.x, ...), this workspace
is configured to keep them fully separate. Thus we have separate solutions,
git clone sets, installation prefixes, etc.

| xserver-master | XLibre Xserver `master` branch and current drivers       |
| xserver-25.1   | XLibre Xserver `release/25.1` branch and current drivers |
| xserver-25.0   | XLibre Xserver `release/25.0` branch and current drivers |

Additional notes:
-----------------

* git tags are intentionally synced into per-remote namespaces
* installation is done is under `_WORK_/<branch>/target`
