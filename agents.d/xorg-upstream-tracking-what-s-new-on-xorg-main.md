---
slug: xorg-upstream-tracking-what-s-new-on-xorg-main
title: "xorg upstream tracking (what's new on `xorg/main`)"
order: 120
---

## xorg upstream tracking (what's new on `xorg/main`)

We follow the upstream X.org server (`xorg` remote → `xorg/main`; note `xorg/master` is
**closed/superseded**, ignore it). XLibre is a long-diverged fork (thousands of commits each side),
so a plain `origin/master..xorg/main` patch-id diff is **useless** — it reports hundreds of false
"missing" commits (already fixed differently, reverts of *our* changes, fork divergence).

**Use the tracking branches instead.** For master and **every** release line there is a marker
branch **`tracking/xorg/main-on-<rel>`** (`…-on-master`, `…-on-25.2`, `…-on-25.1`, `…-on-25.0`) that
points *into* `xorg/main` history at the **last upstream commit already evaluated** for that line.
The only set to consider is therefore:

```bash
git -C <clone> fetch xorg
git -C <clone> log --reverse --no-merges --oneline <tracking-branch>..xorg/main   # the genuinely-new commits
```

Workflow per new commit: classify (already-in-tree / N-A / take it), and for the relevant ones open
a master PR (cherry-pick `-x` to preserve provenance + author, add your `Signed-off-by`; for an
upstream subsystem we dropped — e.g. **Xwayland was removed**, commit `c8b81fdbc5` — it's N-A).
Once the whole delta is dispositioned, **advance the tracker** to the `xorg/main` tip (a fast-forward
along `xorg/main`, no force): `git push origin <xorg/main-sha>:refs/heads/tracking/xorg/main-on-<rel>`.

- **Every existing release line MUST have its own tracker.** When a new release line is branched
  (e.g. `release/25.3`), create `tracking/xorg/main-on-25.3` at the same upstream point as the
  others (or the current synced tip): `git push origin <sha>:refs/heads/tracking/xorg/main-on-25.3`.
  (Audit: `git branch -r | grep -E 'origin/(release/|tracking/xorg/main-on-)'` — every `release/<rel>`
  needs a matching `tracking/xorg/main-on-<rel>`.) The `25.2` tracker was once missing and had to be
  added this way.
- Advancing a **release** tracker encodes the decision "nothing in this delta needs backporting to
  that line" — only do it once that's actually true (a release-relevant security/critical fix in the
  delta must be backported first; see the Backport workflow below).
