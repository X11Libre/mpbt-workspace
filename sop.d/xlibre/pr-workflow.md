---
slug: xlibre/pr-workflow
title: "xserver PR workflow — submit via xx-make-pr"
order: 45
---

# xserver PR workflow — submit via xx-make-pr, not manual `gh pr create`

Submitting xserver (and driver) PRs goes through `starfleetctl xx-make-pr`,
**never** through a hand-typed `gh pr create`. The tooling does everything a
proper PR needs in one step; a manual `gh pr create` silently misses parts.

## The rule

Commit on your branch, then run, **from inside the clone**:

```bash
cd _WORK_/xserver-master/sources/xlibre/xserver
/path/to/starfleetctl xx-make-pr <sha>
```

## What xx-make-pr does (beyond opening the PR)

- creates the PR branch from the configured upstream (`origin/master`), cherry-picks your commits, strips any incubator `[PR #N] ` subject prefix
- pushes the branch
- creates the PR with:
  - **assignee** `@me` (`-a @me`)
  - **reviewer team** from `make-pr.reviewers` (`--reviewer X11Libre/dev`)
  - title `(master) <commit subject>`
- afterwards marks the incubator copies of the submitted commits with a
  `[PR #N] ` subject prefix + `PR: <url>` trailer (via a scripted
  GIT_SEQUENCE_EDITOR)

## The config already lives in the clone

`.git/config` of the local xserver clone sets:

```
make-pr.upstream-remote = origin
make-pr.upstream-branch = master
make-pr.reviewers       = X11Libre/dev
```

## What a manual `gh pr create` misses

A PR created by hand has **no assignee and no reviewer team** — the fleet's
review workflow depends on the `X11Libre/dev` team being requested. Verify with
`gh pr view <n> --json assignees,reviewRequests` and compare against a
tooling-created PR of the same series.

If a PR was already created manually, repair it:

```bash
gh api --method POST repos/X11Libre/xserver/issues/<n>/assignees \
    -f 'assignees[]=metux'
gh api --method POST repos/X11Libre/xserver/pulls/<n>/requested_reviewers \
    -f 'team_reviewers[]=dev'        # team slug, not "X11Libre/dev"
```

## After opening the PR

- Run the **bot-review** flow (skill `bot-review`): post the verdict comment
  with the bot banner and apply `bot-review-passed` / `bot-review-changes-requested`.
  This applies to the maintainer's own PRs too.
- Merges into `release/*` are **manual-only, by the maintainer** — never auto-merge
  a release-line PR, regardless of CI or review status.
