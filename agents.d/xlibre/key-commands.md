---
slug: xlibre/key-commands
title: "Key commands"
order: 40
---

## Key commands

Project-specific quick reference. For fleet coordination, session management,
GitHub interaction, CI, and general workspace tooling see the **`starfleetctl`
skill** (`reference.md`).

### Workspace setup

| command | purpose |
|---------|---------|
| `./mpbt-workspace-bootstrap [--shell-hook] [--build] [--all-releases]` | one-shot fresh-clone setup (idempotent) |
| `./install-mpbt` | `go install github.com/metux/mpbt/cmd/mpbt-builder@latest` |

### Build / fetch

| command | purpose |
|---------|---------|
| `./run-fetch.xserver-<release>` | clone/fetch all sources for a release line |
| `./run-build.xserver-<release>` | full build, then deletes `_WORK_/<release>/install` |

### NVIDIA / drivers

| command | purpose |
|---------|---------|
| `scripts/nvidia-abi-check SYM ...` | classify symbols against nvidia blobs |
| `scripts/fetch-nvidia-drivers [version ...]` | download + extract nvidia `.run` installers |
| `scripts/driver-tracker [--update <issue#>]` | cross-repo driver dashboard |
