---
name: backport
description: Backport a merged master PR (or commit) to the maintained release lines (25.2 / 25.1 / 25.0). Use when asked to "backport", port a fix to a release branch, or apply a master change to older releases. Handles per-branch applicability, isolated agent clones, cherry-pick, PR creation, and cross-linking.
---

# Backport a master PR/commit to release lines

Apply a merged **master** change to every applicable release line (`25.2`, `25.1`, `25.0`),
each in its **own isolated agent clone** — never the user's hand-edited
`sources/xlibre/xserver` tree. Run all commands from the workspace root
(`/home/nekrad/src/xorg/mpbt-workspace`).

> **This workflow ends at "open + cross-link the PR". NEVER merge a `release/*` PR.** Merges into
> release lines are manual-only, by the maintainer — green CI / a passing review do not authorize
> a merge. Fixes for existing releases must always be reviewed independently and manually.

Full reference: **AGENTS.md → "Backport workflow"**. This skill is the actionable checklist.

## Inputs

A merged master PR number **or** a commit-ish. If given a PR number, the scripts resolve its
merge commit automatically.

## Procedure (per applicable release)

### 1. Check applicability first — do NOT open a PR blindly

The fix may already be present, or the buggy code may not exist / not be vulnerable on a given
branch. Inspect the actual code on each release branch:

- One file/symbol across all branches at once:
  `scripts/backport-applies <master-path> '<grep-ERE>' [release ...]`
- A single function on one branch:
  `scripts/show-branch-file release/<rel> <master-path> '<symbol>'`
  (auto-resolves the `Xext/<ext>/` ↔ `<ext>/` directory reorg between releases)

Classify each branch: **vulnerable** / **already-fixed** / **N-A**. Only proceed for vulnerable
branches; record the rest in the dashboard (step 4) — don't open an empty PR.

### 2. Apply + submit in one shot

```bash
scripts/backport-commit <release> <commit-ish|PR#>
```

It refreshes the isolated agent clone (`mk-agent-clone`), `cherry-pick -x`'s onto
`rfc/backport-<release>` (keeps original message + `Signed-off-by`, appends
`(cherry picked from commit <sha>)`), then runs `xx-make-pr.sh` to push the PR against
`release/<release>` and tag the incubator with `[PR #NNNN]` + `PR:` trailer.

- A **path-only** mismatch from the `Xext/<ext>/` ↔ `<ext>/` reorg is auto-remapped → still
  one-shot.
- Only a genuine **content** conflict bails. Then do a manual/adapted backport inside the agent
  clone (`scripts/mk-agent-clone <release>` → cherry-pick → resolve → build-verify) and
  `scripts/xx-make-pr.sh <sha>` from within that clone.

### 3. Parallelize across releases freely

Different release clones are fully isolated (separate working trees, push to distinct
`rfc/backport-<rel>` branches). Run 25.2 / 25.1 / 25.0 concurrently. Within one release, give each
agent its own clone name: `scripts/mk-agent-clone <rel> <name>`.

### 4. Cross-link (required)

- Append a **Backport dashboard** table to the **original master PR** — one row per target branch
  with its backport PR (or `—`) and status (`✅ Merged` / `🔄 Open` / `✅ Already contained`).
- Each **backport PR** links back to the original master PR.
- Edit PR bodies via REST, not `gh pr edit` (which fails with the *"Projects classic
  deprecation"* GraphQL error). Write the body to a file, then:
  `scripts/pr-set-body <pr#> <body-file>`

## Gotchas

- Never run `git gc --prune` / aggressive `repack` in the user's `sources/…` clone while agent
  clones (which borrow its objects via alternates) exist.
- `xx-make-pr.sh` rewrites the `rfc/backport-<rel>` history and needs **exclusive** access to its
  clone for its whole runtime — that's why each agent uses its own clone, not a worktree.
