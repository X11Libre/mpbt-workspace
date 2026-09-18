---
slug: xlibre/task-netbsd-lane-pr-3691-red-retries-exhausted
title: "NetBSD CI lane red - retries exhausted (PR #3691)"
status: done
---

## Context
NetBSD CI job failing in GitHub Actions run [#35108104256](https://github.com/X11Libre/xserver/actions/runs/35108104256) - all 3 retry attempts exhausted.

## Resolution
Fixed via PR #3700 (branch `fix/netbsd-ci-build-failures`) which applies the NetBSD-specific fixes that were already present in `fix/netbsd-ci-ssh-fix` branch but not yet on master at the time of the failed run.

See also: `xlibre/task-netbsd-ci-fix-pr-3700` for the fix tracking topic.
