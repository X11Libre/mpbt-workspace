---
title: "What this is"
order: 10
---

## What this is

MPBT workspace that orchestrates building the XLibre X server and ~54 drivers across the release lines (`xserver-master`, `xserver-25.2`, `xserver-25.1`, `xserver-25.0`, and one more clone per future major release). Each release line gets its own git clones, build dirs, and install prefix under `_WORK_/<release>/` (gitignored).
