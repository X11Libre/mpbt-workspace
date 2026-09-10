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
| Baseline detection | `Makefile`: `VERSION`/`PATCHLEVEL`/`SUBLEVEL` (current Volla: 5.10.198) |

For other kernels: same structure, different URLs/refs.

### Determining the target versions (critical)

Two different versions must not be confused:

- **Final target version** (the version the whole effort ends on): **from the
  `Makefile` of the vendor tree** (`VERSION`/`PATCHLEVEL`/`SUBLEVEL` — Volla's
  `volla-15.0-baseline` declares 5.10.198). It is **never** derived from
  individual commits or commit messages. If a task/order names a different
  final version (e.g. `v5.10.264`), verify it against the Makefile — the
  Makefile is authoritative and a conflicting order value is treated as wrong
  until confirmed. The corresponding LTS tag must exist in the clone
  (`lts/v5.10.198` exists).
- **Next interim version** (which mainline tag to rebase onto in the current
  step): determined from the **actual current basis**, not from branch names
  (`step33-v5.6-base` and similar are only reference markers of earlier
  work — they are NOT authoritative). Find the current basis with
  `git describe --tags` on the current `-step<N>` branch head; then the next
  interim version is the **next higher stable mainline release tag** above it.
  Example: basis `v5.4` (`v5.4-111919-...` or merge-base identical for
  v5.4/v5.5/v5.6) → next interim is `v5.5`, then `v5.6`, `v5.7`, ...

## Workspace isolation & repo hygiene (critical)

Previous agents have damaged the shared mpbt-workspace while working on this
task. Protect it — it is a **multi-project worktree**, not a scratch area.

### Temp files — NEVER in the source tree

During conflict resolution you will need to compare file versions (base/ours/
theirs). **Never** write diff output, comparison files, or merge artifacts
directly into the kernel source tree. This includes:

- `our.c`, `their.c`, `base.c`, `merged.c` and similar comparison dumps
- `resolve/`, `resolve_kconfig/` or similar conflict-resolution directories
- `.bak`, `.backup`, `.tmp` files anywhere in the tree
- Any other temporary analysis files

**Instead**, use a dedicated temp directory under `_WORK_/`:

```bash
WORKDIR=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/volla-kernel/tmp
mkdir -p "$WORKDIR"

# Compare versions there:
diff <(git show HEAD:fs/proc/base.c) <(git show HEAD~1:fs/proc/base.c) > "$WORKDIR/base.c.diff"

# Or extract files for manual inspection:
git show HEAD:fs/proc/base.c > "$WORKDIR/base.c.head"
git show v5.5:fs/proc/base.c > "$WORKDIR/base.c.v5.5"
```

**Before every commit**: run `git status --short` in the kernel clone and
verify there are no untracked files in the tree root or subdirectories.
If you find unexpected files, clean them up immediately.

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

### Conflict resolution — how to proceed (not just "don't stop")

When `git rebase` stops on a conflict:

1. **Read the conflict markers** in the conflicted file(s) — `<<<<<<<`, `=======`, `>>>>>>>`.
2. **Understand the conflict**: what did mainline change vs. what did Android/Volla change?
3. **Resolve semantically**: usually the Android/Volla change is the one to keep (it's the vendor delta). If mainline already has the fix, drop the vendor version.
4. **Do NOT dump files** — resolve inline in the editor. Use `_WORK_/volla-kernel/tmp/` only for temporary reference copies.
5. After editing: `git add <file>` then `git rebase --continue`.
6. If the tree diff shows a difference vs. the original, append a reconciliation commit.

**If you're stuck** (too many conflicts, can't determine the right resolution):
- Update your board note: `starfleetctl comms status working --task <slug> --note "blocked: N conflicts in <files>, need guidance"`
- Send a comms message to Enterprise explaining what files conflict and what the choices are.
- **Do NOT abort**, do NOT create temp files in the source tree, do NOT give up.
- Wait for guidance, then continue.

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

### Live progress on the board (keep it current)

Continuously keep your board entry up to date so the flagship / web console can
see progress at a glance:

- **After every meaningful progress point** (especially after any git
  operation: rebase step applied, conflict resolved, `--continue`), update
  your ship note (`starfleetctl comms status working --task <slug> --note
  "rebase X/Y commits (onto v5.5)"`). Use the actual commit counters from the
  running rebase (`git rebase --show-current-patch` / `.git/rebase-merge/msgnum`
  and `end`).
- Keep the note short and current — replace it, don't append history.
- The board (CLI and web) renders the note automatically; this is the live
  progress indicator. No other status field is needed for progress data.
- Never let the note go stale for long: stale notes look like a stalled ship.

## Known bad behavior — do not repeat

- A previous agent ran `git rebase --abort` on a rate limit, rolled back, and
  gave up (leaving only a backup branch).
- Another stopped doing anything after unexpectedly-finished git calls.
- Some agent damaged the shared workspace: checked out `master` in the
  workspace root, twisted remotes onto xlibre/xserver URLs, and checked out an
  xserver branch — corrupting the environment for everyone. See the workspace
  isolation section above.
- A session targeted the wrong interim version because it read the version from
  branch names / assumed `v5.6` while the actual basis was `v5.4` (→ must be
  `v5.5`). Next interim version always comes from the current basis
  (`git describe --tags` / merge-base), never from branch names or tagnames.
- Another wanted to derive the final target version from individual commits.
  The final target comes from the **vendor tree's `Makefile`**
  (`VERSION`/`PATCHLEVEL`/`SUBLEVEL` → Volla: 5.10.198 = `lts/v5.10.198`),
  never from commit content or messages. A conflicting task/order value
  (e.g. v5.10.264) must be checked against the Makefile first.
- **Barcley (2026-09-09)**: dumped 37 diff-comparison files (`our.c`,
  `their.c`, `base.c`, `merged.c` + variants, `resolve/` dirs) directly into
  the kernel source root during conflict resolution. Also left `.bak`,
  `.backup`, `.tmp` files in subdirs. Cleaned up by Enterprise. Cause: missing
  temp-file hygiene rule in the skill. Added "Temp files — NEVER in the source
  tree" section above.

## Anti-patterns (explicit)

- **No** blanket fat-diff against upstream — the complete history is needed,
  just cleaned up.
- A conflict stop by git is **not** an error: resolve it and `--continue`.
- Only an immediately-recognizable, semantically wrong conflict resolution may be
  repaired step-by-step — never a global reset.