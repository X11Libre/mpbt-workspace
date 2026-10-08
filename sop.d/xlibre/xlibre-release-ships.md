---
slug: xlibre/xlibre-release-ships
title: "Standing release ships XL-0/XL-1/XL-2 (xlibre release work)"
order: 45
---

## Standing ships for xlibre release branches

Three dedicated ships, one per release line, model `heavy-model` (Dreadnought strategy):

| Ship | Release | mpbt Clone | Target Branch | Tracker Branch | Incubator Branch |
|------|---------|------------|---------------|----------------|------------------|
| **XL-0** | 25.0 | `_WORK_/xserver-25.0/sources/xlibre/xserver` | `release/25.0` | `tracking/xorg/main-on-25.0` | `rfc/backport-25.0` |
| **XL-1** | 25.1 | `_WORK_/xserver-25.1/sources/xlibre/xserver` | `release/25.1` | `tracking/xorg/main-on-25.1` | `rfc/backport-25.1` |
| **XL-2** | 25.2 | `_WORK_/xserver-25.2/sources/xlibre/xserver` | `release/25.2` | `tracking/xorg/main-on-25.2` | `rfc/backport-25.2` |

### Responsibility

Each ship owns **its release completely**:

- **Own backports** (`backport-ours`): our merged master PRs → this release branch, one PR per branch, per-task branches (`rfc/backport-25.X-<task>`).
- **xorg/main backports** (`backport-xorg-main`): new `xorg/main` commits → this release, via the per-target incubator (`rfc/backport-25.X`) and tracker (`tracking/xorg/main-on-25.X`).
- Both workflows apply Release Rule: **only bugfixes** (crash, data corruption, UAF, security, build-breaks) — no features, refactorings, or style changes.

### Workspace rules

- **Never write in the shared primary clones** (`_WORK_/xserver-master`, `_WORK_/xserver-<rel>` roots). Use `starfleetctl worktree add <repo-path> <name>` → worktree under `_WORK_/worktrees/xserver/<name>`, branch `wt/<name>`.
- **Never edit another release's branches/incubators**. XL-0 touches only `release/25.0`, `rfc/backport-25.0`, `tracking/xorg/main-on-25.0` — not 25.1/25.2.
- **Announce before starting**: `comms tell <other-ship>` + Board update when touching a release branch or incubator.
- **One ship per release at a time**. If another ship is active in your release, coordinate via comms first.
- **Publish findings on the bus** immediately (comms + dashboard), not just in final report.

### Handover of existing work (2026-10-08 state)

| Release | Open items | Current owner → Target |
|---------|------------|------------------------|
| 25.2 | Phase III rest (~21 commits, 5 open PRs: #3853, #3854, #3855, #3565, #3570) | Galaxy (Phase I+II done) → **XL-2** |
| 25.1 | PR #3859 (Phase I+II, 27 commits, meson setup broken: `xorgserver_lib` missing) | Interpid + Defiant review → **XL-1** |
| 25.0 | No incubator; individual backports (#3858 ns3514, -3776, -misyncfd, -signal-logging, -test-exit-code) | Barcley claimed "Deckung 24+51=72" (CVE pick) → **XL-0** |

**Rule**: open PRs and incomplete work stay with current author until merged/closed. Handover happens via explicit comms directive ("I'm taking over #3859" + `task assign`), not by assumption.

### Spawn / Respawn

```bash
# First spawn (per ship)
./.starfleet-ai/bin/starfleetctl session ship-run --name XL-0 --model heavy-model
./.starfleet-ai/bin/starfleetctl session ship-run --name XL-1 --model heavy-model
./.starfleet-ai/bin/starfleetctl session ship-run --name XL-2 --model heavy-model
```

- `--model heavy-model` (strategy `heavy-model`, Dreadnought class) — **REQUIRED**.
- Launch type: `background` (detached). `session stop` only for `background`/`auto` ships.
- On restart after crash: new `ship-run` with same `--name` (reuses name after `session stop` cleanup).
- Flagship (Enterprise) monitors board; if ship is `idle` > 2h without assignment, nudge or reassign.

### Tooling references

- `backport-ours` skill (our master PRs → release)
- `backport-xorg-main` skill (xorg/main → release)
- `android-kernel-rebase` skill (temp-file hygiene, conflict resolution via `--ours`/`--theirs`, `GIT_EDITOR=:`)
- `branch-hygiene` skill (stale branches, zipper rebase)
- `xorg-main-backport-exclusions.md` (versioned Auslass-Konvention in `sop.d/xlibre/`)