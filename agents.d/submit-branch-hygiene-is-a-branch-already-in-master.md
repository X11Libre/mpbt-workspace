---
slug: submit-branch-hygiene-is-a-branch-already-in-master
title: "submit/* branch hygiene — is a branch already in master?"
order: 170
---

## submit/* branch hygiene — is a branch already in master?

The `submit/*` branches are old staging branches that diverge from current `master` by
**thousands of commits** (one checked had a merge-base ~5000 commits back) **and** straddle the
`Xext/<ext>/` directory reorg. That breaks every single-method "is it merged?" test — each has a
blind spot:

- **`git cherry` / patch-id** ("forward patch present in master history"): blind to **reverts** —
  a later `Revert "…"` in master leaves the forward patch in history, so a reverted-and-thus-*absent*
  change still reads as "contained" (seen on `glamor-unexport`).
- **`git merge-tree --write-tree` vs master tree**: a clean `CONTAINED` (merged tree == master tree)
  or `DIFFERS` (clean merge, tree changes ⇒ genuinely **not** contained, e.g. a revert) is reliable,
  but on these stale branches the 3-way merge **CONFLICTs** purely from the file-move reorg — a
  false negative for branches that *are* fully merged (e.g. `dix-cleanup`, 55 commits all in master).
- **Test-rebase onto master** (`git rebase --empty=drop`): inherits the patch-id revert blind spot
  (drops the commit as "already applied"); `--reapply-cherry-picks` over-corrects and CONFLICTs on
  staleness. `git apply -R` of the cumulative diff is too strict (surrounding-context drift).

**Working recipe** (used June 2026 to clear 79 of ~150 submit branches):
1. **Reliable-positive delete set** = `merge-tree` CONTAINED (bulletproof), *plus* patch-id-clean
   branches (`git cherry` 0 `+` lines) **minus** anything flagged by either (a) `merge-tree`
   `DIFFERS` or (b) a **fuzzy** revert-message scan (master's revert subject often carries a
   `(!NNNN)` prefix, so match the branch's commit subject as a *substring* of `Revert "…"`
   subjects — exact match misses them). Always `gh pr list` first; deleting a branch with an open
   PR closes it.
2. **"Hochziehen" (pull pending branches up onto master):** a full rebase replays the
   already-merged commits too, which is what mostly conflicts — instead cherry-pick **only the
   genuinely-missing commits** (forward patch-id not in master) onto `origin/master`. Even so,
   expect most to still **conflict on real content** (the new commits touch heavily-reorged
   subsystems) — those need manual, build-verified rebasing and must **not** be auto-pushed.
   Only force-push the ones that rebase/cherry-pick **cleanly**.

Do all of this in a **separate detached worktree** (`git worktree add --detach … origin/master`),
never the user's checkout — and note the user may be switching branches / rebasing in the same
clone concurrently (their reflog churn is theirs, not yours). The throwaway analysis scripts live
in the session scratchpad (`classify.sh`, `cherrypick-missing.sh`); promote to `scripts/` only if
this becomes recurring.

**Incremental "zipper" rebase for deeply-stale branches.** `~/.bin/git-zipper-rebase.sh`
(`git zipper-rebase <target>`) rebases a branch onto `<target>` **one upstream commit at a time**
(`git rebase --onto TARGET~N …` for N=X-1…0), so conflicts come in small per-commit bites instead of
one giant merge — useful for the `submit/*` branches whose merge-base is thousands of commits back.
Caveat: for a branch ~4000 commits behind master that's ~4000 sequential `git rebase` invocations
(measured ~2.4/s → tens of minutes per branch), and each conflict stops the run (resolve →
`git zipper-rebase --continue`). Its default target is `origin/main`; pass `origin/master`
explicitly. The harness's 120s foreground Bash timeout can interrupt a long run mid-step and leave a
stale `$GIT_DIR/rebase-zipper.lock` + one-step-behind state file — reconcile the state to HEAD and
resume. Many "stale but contained" branches simply empty out (every commit becomes redundant); a few
reveal a genuinely-new commit hiding under merged ones (this is how `bugfix-xnest-colordepth` and
`recv-fds` were recovered from the "abandon" pile).
