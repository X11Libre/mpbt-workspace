---
name: bootstrapping
description: "Workspace bootstrapping — one-shot fresh-clone setup, template/symlink system for drivers. Use when setting up a fresh mpbt-workspace clone, understanding the driver YAML template system, or troubleshooting bootstrap issues."
---

# Workspace bootstrapping

Set up a completely fresh `git clone` of the mpbt-workspace with one command, and understand the
template/symlink system that keeps ~54 driver configs DRY.

Full reference: **`reference.md`** in this skill's directory. This skill is the actionable checklist.

## One-shot setup

```bash
./mpbt-workspace-bootstrap [--shell-hook] [--build] [--all-releases]
```

1. Checks required tools (`git`, `go`, `gh`) — fails fast if missing
2. Runs `./install-mpbt`
3. Fetches `xserver-master` (default release line)
4. Fetches + builds sister projects (go-x11proto, flyingtux, starfleetctl)
5. Reports shell integration (never edits dotfiles unless `--shell-hook`)

## Optional flags

- `--build` — full xserver-master build (~54 drivers + xts + piglit), slow
- `--all-releases` — fetch xserver-25.0/25.1/25.2 (fetch only, no build)
- `--shell-hook` — auto-add `starfleetctl ship-names shell-env` to `~/.bashrc`/`~/.zshrc`

Idempotent — safe to re-run on an already-bootstrapped clone.

## Template/symlink system

Most ~54 drivers use the same autotools build pattern. Instead of repeating YAML 54 times:

- **Template:** `cf/_common/packages/xlibre/generic-driver-autotools.tmpl.yaml`
- **Symlinks:** each per-release driver `.yaml` symlinks to the template
- **Regeneration:** `cf/xserver-master/packages/xlibre/update-generic.sh`
- **Special cases:** `xserver` (meson), `elographics`, `wacom` (own YAML)
