---
slug: bigfont-xlibre-bigfont-consolidate-cleanup-branch-has-no-act
title: "bigfont: `xlibre/bigfont-consolidate-cleanup` branch has no actual commit"
category: parked
noted_by: "agent clone `_WORK_/xserver-master/agent/rhel-ci/xserver`"
since: "2026-07-01"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

`BIGFONT.md` calls this branch "ready, not pushed" (drop redundant `XF86BigfontResetProc`), but its tip is identical to `origin/master` — the intended commit was never made (or got lost). Needs to be (re)authored before it can be pushed/PR'd
