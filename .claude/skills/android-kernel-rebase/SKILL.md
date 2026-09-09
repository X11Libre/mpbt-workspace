---
name: android-kernel-rebase
description: "Rebase an Android vendor kernel onto its mainline base with clean, linear history while keeping the resulting source tree byte-identical to the original. Use when rebasing/re-linearizing an Android kernel (e.g. Volla mt8781), continuing an interrupted kernel rebase, or cleaning up a messy merge/cherry-pick history onto mainline releases."
---

# Android kernel rebase — linearize onto mainline base

Rebase an Android vendor kernel onto its mainline base tag-by-tag, producing a
clean **linear** history while keeping the **final source tree identical** to the
original Android tree. Only the history is cleaned up — never the code.

## WATCH OUT — the three failure modes that must never happen

1. **Never `git rebase --abort` and never hard-rollback** (no `git reset --hard`,
   no branch deletion) out of frustration or time pressure.
2. **Never stop on transient errors** (rate limits, model errors, dead proxy,
   timeouts) — keep working, don't wait.
3. **Never stop doing anything after an unexpectedly-finished git call** — inspect
   the actual state and continue.

These have all happened to previous agents on this task and each one destroyed
progress. A git command exiting non-zero is **not** a reason to roll back.

## Goal & invariants

- **Target base**: the highest mainline release used in the Android tree, detected
  from the kernel `Makefile` (`VERSION` / `PATCHLEVEL` / `SUBLEVEL`).
- **Content identity**: the final source tree must equal the **original** Android
  tree. If a rebase leaves any content diff behind, append the inverse diff as a
  final reconciliation commit until both trees are identical.
- **Linear history**: above the common ancestor with mainline there must be no more
  merge commits.

## Prerequisites

- The Android kernel tree is already linearized so far that everything above a
  common ancestor with the mainline kernel is linear (no remaining merges).

## Configuration

Generic layout; the Volla mt8781 kernel is the concrete embedding.

| Item | Volla example |
|---|---|
| Clone path | `_WORK_/volla-kernel/sources/volla/kernel-mt8781` |
| Remotes | `volla`/`origin` (HelloVolla vendor), `linux` (torvalds), `lts` (gregkh stable), `mediatek` (BSP) |
| Tag namespaces | `volla/`, `linux/`, `lts/`, `mediatek/` |
| Branch pattern | `<stem>-step<N>` (optionally `wip/` prefix), e.g. `wip/linearize-volla-15.0-step33` |
| Target detection | `Makefile`: `VERSION`/`PATCHLEVEL`/`SUBLEVEL` (current Volla: 5.10.198) |

For other kernels: same structure, different URLs/refs.

## Workspace isolation & repo hygiene (critical)

Previous agents have damaged the shared mpbt-workspace while working on this
task. Protect it — it is a **multi-project worktree**, not a scratch area.

- **Trade only in the kernel clone.** All git work happens inside the kernel
  clone (e.g. `_WORK_/volla-kernel/sources/volla/kernel-mt8781`). The workspace
  root (`/home/nekrad/src/xorg/mpbt-workspace`) is a separate repo with its own
  branch and remotes — never `git checkout`/`git reset`/`git remote` there as
  part of this task.
- **Never re-point remotes.** The kernel clone's remotes are carefully set up
  (vendor, torvalds/`linux`, gregkh-stable/`lts`, BSP/`mediatek`). Do **not**
  change URLs, rename remotes, or add/remove them. If you ever find a remote
  pointing at the wrong project (e.g. an xlibre/xserver URL), that is a
  symptom of workspace corruption — stop, restore the correct URL from the
  workspace's solution config (`run-fetch.<solution>` / `devuan.yaml` /
  package YAML), and report it.
- **Never check out a foreign branch.** Do not check out xserver branches,
  other solutions' branches, or workspace-root branches inside the kernel
  clone (or anywhere else). Stay on the `…-step<N>` branch you are working on.
- **Never touch the workspace root branch.** The workspace root stays on its
  own configured branch (e.g. `mtx/agent-config`); do not switch it, do not
  merge/pull unrelated branches, do not push it without going through the
  normal commit tooling.
- **Before you start a session** (and after any interruption), verify you are
  in the right place before touching anything:
  1. `git rev-parse --abbrev-ref HEAD` in the kernel clone → your `…-step<N>`
     branch.
  2. `git remote -v` in the kernel clone → correct URLs (vendor/torvalds/
     stable/BSP only).
  3. `git status --short` in the kernel clone → only what you expect.
  4. Workspace root branch unchanged (`git -C <root> branch --show-current`).
- If anything is off (wrong branch, wrong remote, foreign files): **restore it
  first, then continue**. Do not "work around" a corrupted checkout — a wrong
  base silently produces a wrong rebase.

## Procedure

### Phase 1 — Incremental rebase up to the highest used mainline release

1. Branch off a new branch; bump the trailing counter in the name; **keep all
   earlier branches as backups** (never delete them).
2. Rebase onto the next higher mainline release tag. Example: if the last used
   mainline tag in the tree was `v5.5`, rebase onto `v5.6`, then `v5.7`, ...
   Ignore LTS tags (third component) in this phase.
3. Resolve every conflict **semantically** (look at the original commits/diffs
   first) so the Android-side changes are carried over cleanly.
4. If git halts mid-rebase, inspect what is going on, repair, and **continue** —
   never abort.
5. After each step the before/after trees must be content-identical; otherwise
   append the inverse diff as a final commit.
6. When the step is done, branch off again (bump the counter) and continue with
   the next higher mainline version — loop until the highest mainline version
   used in the tree is reached (excluding LTS subversions).

### Phase 2 — Incremental rebase within the LTS subversions

1. Same flow as Phase 1, but with the LTS versions the tree used. If the target
   version (from the `Makefile`) is `X.Y.Z`, Phase 1 must have arrived at `X.Y`
   (or `X.Y.0`); then continue with `X.Y.1`, `X.Y.2`, ... `X.Y.Z`.

## Resilience layer — how to keep working

### Transient errors → keep working, don't stop

- Pause briefly, retry. If the same API level keeps failing, work on another
  independent part of the current step instead of waiting (inspect the next
  conflict, analyze the next diff, prepare the tree reconciliation).
- Only if a blockage persists: document the exact state, report to flagship and
  McKinley — but **never abort the rebase**.

### Unexpectedly-finished git call (exit != 0, no clear message)

**Determine state first, then decide** — never act on assumption:

1. `git status --short` — clean? Rebase in progress?
2. `.git/rebase-merge` or `.git/rebase-apply` present? → mid-rebase: resolve
   conflicts, `--continue`.
3. `git log -1 --oneline` — did the expected commit already land? → just continue
   (the call probably wasn't really a failure).
4. Nothing happened (trees identical) → re-run the step idempotently.

### Idempotency

Every step must be re-runnable: check the invariant before restarting
(merge-base, tree diff against the baseline) so that re-running is safe.

## Reporting

After every release step: submit a report (`starfleetctl reports submit`) and
send a comms message to **Enterprise** (flagship) **and** **McKinley**
(="Starbase"); the report must prove the tree reconciliation ran.

## Known bad behavior — do not repeat

- A previous agent ran `git rebase --abort` on a rate limit, rolled back, and
  gave up (leaving only a backup branch).
- Another stopped doing anything after unexpectedly-finished git calls.
- Some agent damaged the shared workspace: checked out `master` in the
  workspace root, twisted remotes onto xlibre/xserver URLs, and checked out an
  xserver branch — corrupting the environment for everyone. See the workspace
  isolation section above.

## Anti-patterns (explicit)

- **No** blanket fat-diff against upstream — the complete history is needed,
  just cleaned up.
- A conflict stop by git is **not** an error: resolve it and `--continue`.
- Only an immediately-recognizable, semantically wrong conflict resolution may be
  repaired step-by-step — never a global reset.