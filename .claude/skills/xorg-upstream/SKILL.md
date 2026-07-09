---
name: xorg-upstream
description: Track upstream X.org server (`xorg/main`) against the long-diverged XLibre fork using the `tracking/xorg/main-on-<rel>` marker branches. Use when syncing upstream commits, classifying what's new on xorg/main, or advancing a tracking branch.
---

# xorg upstream tracking (what's new on `xorg/main`)

Full detail: **`reference.md`** in this skill's directory (moved out of AGENTS.md).

Run commands from a release clone under `_WORK_/` (`/home/nekrad/src/xorg/mpbt-workspace`).

## Mental model

- Upstream is `xorg` remote → `xorg/main`. **`xorg/master` is closed/superseded — ignore it.**
- XLibre is a long-diverged fork, so `origin/master..xorg/main` patch-id diffs are useless (hundreds
  of false "missing" commits). Use the **tracking marker branches** instead.
- For master and **every** release line there is `tracking/xorg/main-on-<rel>`
  (`…-on-master`, `…-on-25.2`, `…-on-25.1`, `…-on-25.0`) pointing *into* `xorg/main` at the last
  upstream commit already evaluated for that line.

## Procedure

1. The only set to consider is what's genuinely new since the tracker:

   ```bash
   git -C <clone> fetch xorg
   git -C <clone> log --reverse --no-merges --oneline <tracking-branch>..xorg/main
   ```

2. Per new commit: classify (already-in-tree / N-A / take it). For the relevant ones open a master PR
   — cherry-pick `-x` to preserve provenance + author, add your `Signed-off-by`. Dropped upstream
   subsystems (e.g. Xwayland, commit `c8b81fdbc5`) are N-A.

3. Once the whole delta is dispositioned, **advance the tracker** (fast-forward along `xorg/main`, no
   force):

   ```bash
   git push origin <xorg/main-sha>:refs/heads/tracking/xorg/main-on-<rel>
   ```

## Rules

- **Every existing release line MUST have its own tracker.** When a new release line is branched
  (e.g. `release/25.3`), create `tracking/xorg/main-on-25.3` at the same upstream point as the
  others. Audit: `git branch -r | grep -E 'origin/(release/|tracking/xorg/main-on-)'` — every
  `release/<rel>` needs a matching `tracking/xorg/main-on-<rel>`.
- Advancing a **release** tracker encodes "nothing in this delta needs backporting to that line" —
  only do it once that's true (backport a release-relevant security/critical fix first).
