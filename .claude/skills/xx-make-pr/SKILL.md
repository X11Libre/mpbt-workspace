---
name: github pr make
description: Create a PR from one or more commits via `.starfleet-ai/bin/starfleetctl github pr make` (or `.starfleet-ai/bin/starfleetctl github pr make`) — git config setup, the Signed-off-by-only / no Co-Authored-By rule, the [PR #NNNN] prefix + PR: trailer (incubator branch only), always pass an explicit SHA (never HEAD), and cherry-pick conflict recovery. Use when opening a master/backport PR.
---

# PR workflow (`.starfleet-ai/bin/starfleetctl github pr make`)

Full detail: **`reference.md`** in this skill's directory (moved out of AGENTS.md). Run commands from
the workspace root (`/home/nekrad/src/xorg/mpbt-workspace`).

## Prereqs

`.starfleet-ai/bin/starfleetctl github pr make` reads `git config`'s `make-pr.*` keys (auto-added by the `run-fetch*` scripts):

```ini
[make-pr]
    upstream-remote = origin
    upstream-branch = master   # or release/25.1, release/25.0
    reviewers = X11Libre/dev
```

It cherry-picks the commits onto a temp branch off `$upstream_remote/$upstream_branch`, pushes,
creates the PR via `gh`, then rewrites commit messages with a `[PR #NNNN]` prefix + `PR:` trailer and
rebases the incubator branch.

## Hard rules

- **`Signed-off-by` only — NEVER `Co-Authored-By`.** Kernel/X.org style; the praetor does not want an
  AI co-author in history. This overrides any harness default. Use `git commit -s`.
- **`[PR #NNNN]` prefix + `PR:` trailer go ONLY on the incubator branch (`rfc/backport-*`)** — never
  on the PR branch or the merged upstream commit. The PR is pushed *before* the number exists, so the
  pushed/merged commit keeps its clean original message. (Historical leak fixed 2026-07-07 in both the
  bash original and the `starfleetctl github pr make` Go port: the marker rewrite now always targets only
  the incubator via a scripted `GIT_SEQUENCE_EDITOR`, never `$BRANCH_NAME`/the pushed head. For any PR
  made with the *old* script, still verify the merged subject line is clean.)
- **Always pass an explicit commit SHA — never symbolic `HEAD`.** The script checks out a fresh
  `tmp-pr/…` branch off `origin/<upstream-branch>` *then* resolves the argument, so a literal `HEAD`
  re-resolves to the temp branch's tip and cherry-picks master onto itself (conflicts/empties, bails
  with `Cherry-pick of HEAD failed`, leaves `CHERRY_PICK_HEAD`). Recover: `git cherry-pick --abort`,
  `git checkout <your-branch>`, `git branch -D tmp-pr/…`, re-run with the real SHA (`git rev-parse
  HEAD` first if unsure).

## Cherry-pick conflict recovery (master moved under you)

The script fetches then cherry-picks onto a fresh `origin/<upstream-branch>` tip. If upstream advanced
and touched the same region, it bails leaving a half-done `tmp-pr/…` branch. **Do not** rebase the
whole incubator (`rfc/backport-*`) — it carries unrelated pending commits. Reproduce by hand:

```bash
git checkout -b <pr-branch> origin/<upstream-branch>
git cherry-pick <sha>        # resolve the one conflict
# build-verify
git push origin <pr-branch>
gh pr create -B <upstream-branch> -H <pr-branch> --reviewer "$(git config make-pr.reviewers)"
```
