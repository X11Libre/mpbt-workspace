---
slug: mpbt/what-this-is
title: "MPBT subdir — workspace build orchestration"
order: 1
---

## MPBT subdir

Instructions for working with MPBT — the multi-project build tool
that orchestrates building the X server and ~54 drivers across the
release lines (`xserver-master`, `xserver-25.2`, `xserver-25.1`,
`xserver-25.0`).

This covers `_WORK_/` layout, build commands, temp dir conventions,
and any MPBT-specific workflows that don't belong in `project/`
(workspace meta) or `starfleet/` (fleet coordination).
