# xserver PR workflow — submit via xx-make-pr

Submitting xserver (and driver) PRs goes through `starfleetctl xx-make-pr`,
**never** through a hand-typed `gh pr create`. The tooling does everything a
proper PR needs in one step; a manual `gh pr create` silently misses parts.

## When to use

Use this skill when you need to create a PR for the xserver or a driver
within the mpbt-workspace, ensuring the PR includes the required assignee,
reviewer team, and proper title formatting.

## How to use

1. Commit your changes on a branch inside the appropriate clone
   (e.g. `_WORK_/xserver-master/sources/xlibre/xserver`).
2. Run, **from inside the clone**:

   ```bash
   /path/to/starfleetctl xx-make-pr <sha>
   ```

   where `<sha>` is the commit you want to submit.

## What the skill does

- Creates the PR branch from the configured upstream (`origin/master`),
  cherry-picks your commits, strips any incubator `[PR #N] ` subject prefix.
- Pushes the branch.
- Creates the PR with:
  - **assignee** `@me` (`-a @me`)
  - **reviewer team** from `make-pr.reviewers` (`--reviewer X11Libre/dev`)
  - title `(master) <commit subject>`
- Afterwards marks the incubator copies of the submitted commits with a
  `[PR #N] ` subject prefix + `PR: <url>` trailer (via a scripted
  `GIT_SEQUENCE_EDITOR`).

## Configuration

The clone’s `.git/config` already contains:

```
make-pr.upstream-remote = origin
make-pr.upstream-branch = master
make-pr.reviewers       = X11Libre/dev
```

## Manual `gh pr create` pitfalls

A PR created by hand has **no assignee and no reviewer team** — the fleet’s
review workflow depends on the `X11Libre/dev` team being requested. If a PR
was already created manually, repair it:

```bash
gh api --method POST repos/X11Libre/xserver/issues/<n>/assignees \
    -f 'assignees[]=metux'
gh api --method POST repos/X11Libre/xserver/pulls/<n>/requested_reviewers \
    -f 'team_reviewers[]=dev'        # team slug, not "X11Libre/dev"
```

## After opening the PR

- Run the **bot-review** flow (skill `bot-review`): post the verdict comment
  with the bot banner and apply `bot-review-passed` /
  `bot-review-changes-requested`.
- Merges into `release/*` are **manual-only, by the maintainer** — never
  auto-merge a release-line PR, regardless of CI or review status.

