---
slug: architecture
title: "Architecture"
order: 60
---

## Architecture

- **`cf/_common/packages/xlibre/`** — shared package YAML definitions (the source of truth)
- **`cf/<release>/packages/xlibre/`** — per-release overrides; most driver files are **symlinks** back to `_common/`
- **`cf/<release>/solutions/devuan.yaml`** — the solution file: build order, env vars, meson-extra-args
- **`cf/<release>/config.sh`** — sets `XLIBRE_RELEASE`, `PATH`, `MPBT`, `SOLUTION`, `WORKDIR`

Build order and which packages to build is defined in each solution's `build:` list.
