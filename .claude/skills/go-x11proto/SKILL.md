---
name: go-x11proto
description: "Sister project integration (go-x11proto, FlyingTux, starfleetctl) — mpbt solution layout, build, fetch, and workflow for non-xserver projects in the workspace. Use when working on go-x11proto, FlyingTux, or starfleetctl within the mpbt-workspace, or when integrating a new sister project."
---

# Sister project integration

Non-xserver projects (go-x11proto, FlyingTux, starfleetctl) are standalone mpbt solutions with
their own config, workdir, and build — deliberately kept **separate from the xserver build**.

Full reference: **`reference.md`** in this skill's directory. This skill is the actionable checklist.

## Pattern per project

- **Config:** `cf/<name>/{config.sh,solutions/default.yaml,packages/xlibre/<name>.yaml}`
- **Clone:** `_WORK_/<name>/sources/xlibre/<name>` (gitignored)
- **Wrappers:** `./run-fetch.<name>`, `./run-build.<name>`, `./run-opencode.<name>`
- Agents should `cd` into the clone to work on it.

## Quick reference

| Project | Repo | Branch | Build |
|---------|------|--------|-------|
| go-x11proto | `X11Libre/go-x11proto` | `staging` | `make` (pure Go) |
| FlyingTux | `metux/flyingtux` | `master` | no-op (plain Python) |
| starfleetctl | `mpbt-hq/starfleetctl` | `master` | `make` (pure Go) |

## Gotchas

- `run-fetch.*` does NOT fast-forward checked-out branch — run `git merge --ff-only origin/master` before rebuilding
- FlyingTux has Python-2-only syntax (`chmod 0755`) — don't `python -m compileall` it
- `starfleetctl` was moved from `metux/starfleetctl` to `mpbt-hq/starfleetctl` (2026-07-06)
