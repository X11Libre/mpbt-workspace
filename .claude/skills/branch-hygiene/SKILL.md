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

## A branch name is not a lifecycle

A prefix says who created a branch, not whether it may go. Measured 2026-10-01 on the six
`wt/*` branches in the xserver clone: two had **no registered worktree** and carried 32 and
10 commits that existed nowhere else — one matched `xlibre/bool-bool-phase-out`
("ongoing, opportunistic"), the other the QEMU arch lanes. They look like tool leftovers
and are not.

Conversely `tmp-pr/release/25.x` on origin carried one real bugfix each that is on master
but on **no** release line. Deleting them as "staging leftovers" would have abandoned two
backports.

**Disposability needs two measurements, both commands, no pattern:**

```sh
starfleetctl worktree list | awk -F'\t' '$NF=="'"<branch>"'"'   # empty = no worktree owns it
gh pr list --repo <repo> --state all --head <branch>             # open PR?
git cherry origin/master <branch> | grep '^+'                     # empty = nothing of its own left
```

Both must hold. `git cherry` is the content check and the only trustworthy one: `--head`
searching for a PR **finds nothing** when the work was submitted by `make-pr`, because that
pushes `pr/<base>-<slug>_<timestamp>`, not the branch you are holding. That mistake made me
call a merged PR "not backported" and a live branch "disposable" in the same hour.

`starfleetctl worktree list` is **tab**-separated. `grep " $branch$"` with a space matches
nothing and reports "no worktree" for a branch that has one — a false positive in the
dangerous direction, since it invites deleting a branch that is still in use.

## Namespaces

| prefix | owner | meaning |
|---|---|---|
| `tmp-pr/…` | `make-pr.sh` / `xx-make-pr` only | staging; `tmp-pr` as an exact branch name blocks the namespace (git D/F conflict) |
| `wip/…` | any ship | keep — the work lives only here |
| `wt/…` | `starfleetctl worktree add` | has a registered worktree, **not** "disposable" |
| `rfc/…` | shared incubator | never rebase or force-push without its owner |

An aborted run leaves the staging branch behind on purpose (recoverable cherry-pick state),
so leftovers are expected and are not evidence of a bug. Rescue-ref first, delete second.

## Zipper rebase

`git zipper-rebase <target>` rebases one commit at a time — useful for branches thousands of commits behind. Slow (~2.4/s) but conflicts come in small bites.
