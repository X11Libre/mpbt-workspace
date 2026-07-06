---
slug: hurd-ci-job-can-hang-with-no-timeout
title: "Hurd CI job (`xserver-build-hurd`) can hang with no timeout"
category: parked
noted_by: "run 28600347199 / job 84806756748 (PR #3231), cancelled by praetor after ~33m; `.github/scripts/hurd/run-vm-build.sh` (QEMU), see `AGENTS.md` \"Hurd CI\""
since: "2026-07-02"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Step "Boot GNU/Hurd VM and build (Xvfb+Xnest)" wedged ~33min with **no per-job/step timeout** → had to be cancelled by hand (otherwise it burns to the 6h runner cap and blocks the PR's other jobs). Fix later: add a `timeout-minutes` to the job/step (or wrap the QEMU run in `timeout` inside `run-vm-build.sh`) so a wedged boot fails fast instead of hanging. Same "no timeout → silent hang" pattern as the xephyr-glamor/XTS row above
