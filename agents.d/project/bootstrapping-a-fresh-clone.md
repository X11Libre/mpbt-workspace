---
title: "Bootstrapping a fresh clone"
order: 30
---

## Bootstrapping a fresh clone

**Goal: a completely fresh `git clone` of this workspace should be able to rebuild itself with one
command**, instead of an agent/human having to remember and manually replay the right sequence of
`install-mpbt` → `run-fetch.*` → `run-build.*` → shell-integration steps that had accumulated
across many sessions before this existed.

**`./mpbt-workspace-bootstrap [--shell-hook] [--build] [--all-releases]`** is that one command:

1. Checks required tools (`git`, `go`, `gh`) — fails fast if any are missing; warns (non-fatal) on
   optional ones (`tmux`, `meson`, `ninja`, `pkg-config`) and on `gh` not being authenticated.
2. Runs `./install-mpbt`.
3. Fetches `xserver-master` (the default/primary release line — matches the README "Quick start").
4. Fetches **and builds** all sister-project solutions (`go-x11proto`, `flyingtux`,
   `starfleetctl` — see "go-x11proto, FlyingTux and starfleetctl are their own mpbt solutions"
   below): cheap enough (small Go/Python projects) to always do, unlike the full xserver build.
5. Reports the shell integration (`scripts/agent-bus-auto-id.sh` sourced from `~/.bashrc`/
   `~/.zshrc`, see "Ship names for fleet identity" in Concurrency) — but **never edits your
   dotfiles unless you pass `--shell-hook`**; without it, bootstrap just prints the line to add.
   This is the one piece of setup that lives outside the repo (a user dotfile), so it can't be
   "in" a fresh clone by definition — it's the one manual step bootstrap can't fully eliminate,
   only automate on request.

**Deliberately NOT done by default** (opt in, since they're slow/heavy and most sessions only need
one release line): the full `xserver-master` build (~54 drivers + xts + piglit, `--build`), and
fetching the other release lines `xserver-25.0`/`25.1`/`25.2` (`--all-releases`, fetch only —
building those is normally done from a dedicated `mk-agent-clone`, not the user's own checkout
anyway, see Concurrency).

**Idempotent by construction** — every step it calls (`go install ...@latest`, mpbt's `fetch`/
`build`, the dotfile grep-before-append) is safe to re-run on an already-bootstrapped clone (e.g.
after `git pull` picked up a new sister-project solution). Verified 2026-07-03: a full run against
an already-fully-set-up workspace made zero unexpected changes (only the new incremental `git
fetch` deltas under `_WORK_/`, which is gitignored anyway) and correctly reported "shell
integration already present" instead of duplicating the `~/.bashrc` line.

**What's still genuinely manual, even after bootstrap:** `gh auth login` (interactive OAuth, can't
be scripted), an opencode API provider credential (see "opencode session setup" below) if you want
opencode sessions rather than Claude Code, and actually starting a session (`./run-ship`,
`./run-flagship`, `agent-run`, or a plain `claude`/`opencode` in the tree).
