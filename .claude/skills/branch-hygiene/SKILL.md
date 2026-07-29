---
name: branch-hygiene
description: "Branch hygiene — determining if a submit/* branch is already in master, cleaning stale branches, zipper rebase for deeply-stale branches. Use when cleaning up old submit/* branches, checking if a branch's changes are already merged, or rebasing branches with thousands of commits of drift."
---

# Branch hygiene — submit/* cleanup

Determine whether old `submit/*` branches are already merged into master, and clean them up.
These branches often diverge by thousands of commits and straddle the `Xext/<ext>/` directory reorg,
breaking simple "is it merged?" tests.

Full reference: **`reference.md`** in this skill's directory. This skill is the actionable checklist.

## Key methods

1. **`git merge-tree --write-tree` vs master tree** — reliable: `CONTAINED` = merged, `DIFFERS` = not merged. But CONFLICTs from file-move reorg are false negatives on stale branches.
2. **`git cherry` / patch-id** — blind to reverts.
3. **Test-rebase** — inherits both blind spots.

## Working recipe

1. Reliable-positive set = `merge-tree` CONTAINED + patch-id-clean, minus `DIFFERS` and fuzzy revert scan.
2. Always `gh pr list` first — deleting a branch with an open PR closes it.
3. For "hochziehen": cherry-pick **only genuinely-missing commits** onto `origin/master`.
4. Work in a **detached worktree**, never the user's checkout.

## Zipper rebase

`git zipper-rebase <target>` rebases one commit at a time — useful for branches thousands of commits behind. Slow (~2.4/s) but conflicts come in small bites.
