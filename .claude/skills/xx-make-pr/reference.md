
## PR workflow (`.starfleet-ai/bin/starfleetctl github pr make`)

Requires git config entries (these are automatically added by the run-fetch* scripts):

```ini
[make-pr]
    upstream-remote = origin
    upstream-branch = master   # or release/25.1, release/25.0
    reviewers = X11Libre/dev
```

The script cherry-picks commits onto a temp branch based on `$upstream_remote/$upstream_branch`, pushes, creates a PR (via `gh`), then rewrites commit messages with `[PR #NNNN]` prefix and `PR:` trailer, and rebases the incubator branch.

**Commit-message trailer convention — `Signed-off-by` only, NEVER `Co-Authored-By`.** Commits in
all these repos (xserver and the drivers) carry a `Signed-off-by:` trailer (kernel/X.org style)
and nothing else. Do **not** append a `Co-Authored-By:` line (e.g. an AI co-author) — the
praetor does not want it in the history. This overrides any agent/harness default that says to
add one. Use `git commit -s` (or write the `Signed-off-by` explicitly) and stop there.

**The `[PR #NNNN]` prefix + `PR:` trailer belong ONLY on the incubator branch (`rfc/backport-*`) — never on the PR branch or the merged upstream commit.** The PR is pushed *before* the PR number exists, so the pushed/merged commit must keep its clean original message. Leak seen on master: PR #3162 merged 4 commits all prefixed `[PR #3162]`. Root cause was `DEFAULT_MODE="rebase"`: that mode ran the `[PR #N]`/`PR:` marker rewrite against the **PR branch** `$BRANCH_NAME` itself (the head that gets merged), not just the incubator; the alternative `incubator` mode rewrote only the incubator but needed an interactive `git rebase -i`, unsupported in an agent/CI environment — which is why the default had been flipped to the leak-prone mode in the first place. **Fixed 2026-07-07 in both the bash original and the `starfleetctl github pr make` Go port**: the marker rewrite now always targets only the incubator branch, via a scripted `GIT_SEQUENCE_EDITOR` (inserts `exec` only after the todo lines for the submitted commits) instead of a human-driven interactive rebase — `$BRANCH_NAME`/the pushed PR head is never touched again after the push. The `--rebase`/`incubator` mode split (and its CLI flag) is gone; there's only one, correct, non-interactive path now. For any PR created with the *old* script (before this fix), still verify the merged subject line is clean. A second, independent leak vector remains: re-running `github pr make` on an incubator commit that is *already* prefixed re-cherry-picks the prefix onto the fresh PR branch (fixed separately, d01c430) — always submit the clean commit. (Already-merged prefixed commits are left as-is; no master history rewrite.)

**Always pass `github pr make` an explicit commit SHA — never the symbolic `HEAD`.** The script first
`git checkout`s a fresh `tmp-pr/…` branch off `origin/<upstream-branch>`, *then* resolves the commit
argument to cherry-pick. A literal `HEAD` therefore re-resolves to the just-checked-out temp branch's
tip (= current `origin/master`), so it cherry-picks master's own tip onto itself — which conflicts /
empties and bails with `Cherry-pick of HEAD failed`, leaving a half-done `tmp-pr/…` branch and a
`CHERRY_PICK_HEAD` in progress. Recover with `git cherry-pick --abort`, `git checkout <your-branch>`,
`git branch -D tmp-pr/…`, then re-run with the real SHA (`git rev-parse HEAD` first if unsure). (Hit
2026-07-01 creating the CSRG_BASED-cleanup PR #3211 — passing `HEAD` grabbed the freshly-merged
go-x11proto-bump commit instead.)

**Cherry-pick conflict recovery (master moved under you).** The script `git fetch`es then cherry-picks
onto a *fresh* `origin/<upstream-branch>` tip. If upstream advanced and touched the same region as
your commit, the cherry-pick conflicts and the script bails, leaving a half-done `tmp-pr/…` branch.
**Do not** try to fix it by rebasing the whole incubator (`rfc/backport-*`) onto the new tip — the
incubator carries unrelated pending commits that bring their own conflicts. Instead reproduce just
the final steps by hand: `git checkout -b <pr-branch> origin/<upstream-branch>`, `git cherry-pick
<sha>`, resolve the one conflict, build-verify, `git push origin <pr-branch>`, then `gh pr create
-B <upstream-branch> -H <pr-branch> --reviewer "$(git config make-pr.reviewers)"`. (Seen creating
#3130: master had just re-parenthesized the same `include/list.h` macro the commit edited.)
