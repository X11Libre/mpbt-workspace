---
name: starfleet-sessions
description: "Ship session and workspace management — spawning ships, session attach/stop, git worktrees, web console, deployment. Load when launching/administering ships or managing the fleet web console."
---

# starfleet-sessions — ship sessions, worktrees, web console

Spawning and managing ships, isolated worktrees, and the fleet web console.
Comms/task core lives in the **`starfleet`** and **`starfleet-tasks`** skills.

## Ship sessions

| Subcommand | Purpose |
|---|---|
| `run [--flagship\|--name <id>] [--client claude\|opencode]` | Start an AI ship session |
| `session list` | List running detached sessions |
| `session attach <id>` | Attach terminal to a detached session |
| `session stop <id>` | Kill a detached session + release ship name |

Background ships never prompt on their console (see the starfleet-instructions working
practices) — hand them a task via the dashboard/comms, not as extra CLI args.

## Git worktrees

**Always use `starfleetctl worktree …`** — never bare `git worktree` in any workspace
repo, including mpbt-cloned sources under `_WORK_/`. starfleetctl creates and tracks
every worktree under `_WORK_/worktrees/<reponame>/<name>`, so they stay visible to
`worktree list`/`prune` and cannot silently leak as untracked orphan directories with
dangling `wt/*` branches.

| Subcommand | Purpose |
|---|---|
| `worktree add <repo-path> [name] [--from <ref>] [--branch <existing>]` | Create a tracked worktree under `_WORK_/worktrees/<reponame>/<name>` on branch `wt/<name>` |
| `worktree list [repo-path]` | List all tracked worktrees (all repos or one repo) |
| `worktree remove <repo-path> <name> [--force] [--keep-branch]` | Remove a worktree and its `wt/<name>` branch (`--keep-branch` to keep the branch) |
| `worktree prune [repo-path]` | Garbage-collect stale worktree directories |

## Web console & setup

| Subcommand | Purpose |
|---|---|
| `web start/stop/restart/autostart` | Fleet web console (mobile-first) |
| `genesis-init [dir]` | Bootstrap a workspace from nothing |
| `self-install` | Clone/pull + build + symlink starfleetctl |
| `sop install-starfleet` | Install/update SOP fragments and skills |

## Deployment

```bash
# Phase A: genesis (from an existing binary)
starfleetctl genesis-init .

# Phase B: bootstrap (from the committed script)
./starfleet-bootstrap
```

Everything under `.starfleet-ai/` is gitignored. Re-run `./starfleet-bootstrap` anytime to update.