---
slug: xlibre/architecture
title: "Architecture"
order: 60
---

## What this is

MPBT workspace that orchestrates cloning and building the XLibre X server and ~54 drivers across various
release lines, as well as additional related packages (eg. go-x11proto, wich also contains the xnamespace
user tools, as well as an X11 test suite).

Primary structure level are MBPT solutions (eg. one per release line), which define the necessary git repos
as well as build instructions and dependencies. Cloning is done via corresponding `run-fetch.<solution>`,
building via `run-build.<solution>` scripts.

## Architecture

- **`cf/_common/packages/xlibre/`** — shared package YAML definitions (the source of truth)
- **`cf/<solution>/packages/xlibre/`** — per-release overrides; most driver files are **symlinks** back to `_common/`
- **`cf/<solution>/solutions/devuan.yaml`** — the solution file: build order, env vars, meson-extra-args
- **`cf/<solution>/config.sh`** — sets `XLIBRE_RELEASE`, `PATH`, `MPBT`, `SOLUTION`, `WORKDIR`

Build order and which packages to build is defined in each solution's `build:` list.

## Starfleet

Using starfleetctl for inter-agent coordination. Load the (auto-installed) starfleetctl skill!.
Call ./starfleet-bootstrap for installing/updating it.

## directories etc

- `_WORK_/` --> prefix for all working trees and other temporary files
- _never_ use `/tmp` or any other temp directory outside the workspace - create your own ones under `_WORK_/`
- per-package install prefixes: `_WORK_/<solution>/install`, complete image (all package): `_WORK_/<solution>/target`
- pkg-config & aclocal paths are set per-solution in `devuan.yaml` `env:` — they point into the install prefix.
- pulled git tags are namspaced per remote
- when working on individual git repos/projects, also check their AGENTS.md's (if existing)

## which repos / solution to use

- primary xserver development is done on xserver-master solution (and it's corresponding repos)
- existing release lines have their own solutions - as well flyingtux and go-x11proto
- create additional workspaces if applicable (eg. when making bigger changes that could conflict other agents or myself)
- don't try to use any clones outside the mpbt workspace
