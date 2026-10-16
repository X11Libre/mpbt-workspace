Title: "xserver CI flake: display-number race in parallel test/info suites"
Category: parked
Kind: task
Status: "open"
Created-By: "Defiant"
Created: "2026-10-16T08:18:53Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/task-xserver-ci-flake-display-number-race-in-parallel-test-info-suites

SYSTEMIC CI flake (not PR-caused): 'xserver-build-ubuntu-no-gbm' (and other lanes) intermittently fail a display-info subtest. Evidence: run 38766384723 (PR #3981) fails test 3 'xserver:xvfb display info / xdpyinfo'; run 38774811861 (MASTER) fails test 7 'xserver:xehypr-glamor display info / xdpyinfo' with '_XSERVTransSocketUNIXCreateListener: /tmp/.X11-unix/X0 already in use' + '_XSERVTransMakeAllCOTSServerListeners: server already running' repeated for X0/X1/X2..., then 'xdpyinfo: unable to open display :1' / exit 1. Mixed pass/fail across runs (6/12). No 'is_parallel:false' in test/ -> meson runs all display-info tests (xvfb/xehypr/xehypr-glamor) concurrently; each starts Xvfb (and nested Xephyr) via simple-xinit -displayfd; the X server display-allocation loop collides. Fix (proposed): mark display-info tests is_parallel:false in test/info/meson.build; consider a shared startup lock; deeper: -displayfd allocation race in transport.
