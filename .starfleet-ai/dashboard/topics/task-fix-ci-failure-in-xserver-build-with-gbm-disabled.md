---
slug: task-fix-ci-failure-in-xserver-build-with-gbm-disabled
title: "Fix CI failure in xserver build with GBM disabled"
category: active
kind: task
status: open
created-by: Stargazer
created: 2026-08-03T19:06:45Z
assigned-to: —
doc_ref: "—"
---

Resolved CI failure in xserver-build-ubuntu-no-gbm job caused by commit a1acf90c52. The commit incorrectly changed GBM dependency handling, causing GBM feature flags to be undefined when GBM is disabled, leading to byte-swapping errors in randr, render, and present tests. Fixed by reverting the commit to restore proper GBM feature detection via gbm_dep.found() when glamor is enabled. Verified fix: all tests pass (46 OK, 2 skipped) with -Dgbm=false. Reported resolution to Enterprise via agent-bus directive m0002.
