---
title: "CI Hurd lane fails on debian-ports apt dependency conflict (infra flake)"
category: xlibre
kind: "note"
status: "parked"
assigned-to: "Lexington"
tags: "ci,hurd,debian-ports"
doc-ref: "PR #3470, run 30804971205; unrelated master run 30809520166"
---

The `xserver-build-hurd` CI lane (hand-rolled QEMU boot against debian-ports
`sid`/`unreleased`) fails before any build step: `apt-get install` of the
toolchain cannot resolve deps.

## Root cause (precise, verified 2026-08-03 by Lexington)

Deterministic debian-ports inconsistency for `hurd-amd64` — NOT a code bug and
NOT the fault of PR #3470: the identical failure hits unrelated PRs (e.g. master
run 30809520166, "meson.build: Use a `disabler` for the gbm dependency").

- **sid main:** `git` = `1:2.51.0-1`, `git-man` (arch:all) = `1:2.55.0-1`.
  git 2.51.0-1 requires `git-man (>> 1:2.51.0)` AND `(<< 1:2.51.0-.)` → git-man is
  too new → main's git is uninstallable.
- **unreleased:** `git` = `1:2.53.0-1+hurd.1`, `git-man` = `1:2.53.0-1+hurd.1`
  (a coherent pair). But apt prefers the newer arch:all `git-man 2.55.0-1` from
  main over the unreleased `2.53.0-1+hurd.1`, so git's `git-man (< 1:2.53.0-.)`
  constraint can never be satisfied. apt error: "Reached two conflicting
  assignments: 1. git:hurd-amd64=1:2.53.0-1+hurd.1 is selected for install /
  2. git depends git-man (< 1:2.53.0-.)".
- All other deps DO resolve in sid main right now (`libcurl3t64-gnutls 8.21.0~rc3-1`,
  `liberror-perl 0.17030-1`, `python3-setuptools 78.1.1-0.1`, `pkgconf 2.5.1-4`) —
  `git`/`git-man` is the ONLY blocker.

## Workaround (CI, `.github/scripts/hurd/run-xserver-build.sh`)

Pin the coherent unreleased pair for the toolchain install, e.g. a fallback after
the plain install fails:

```sh
sudo apt-get install -y --no-install-recommends \
    git/unreleased git-man/unreleased build-essential meson ninja-build \
    pkg-config ca-certificates
```

## Fix upstream

debian-ports needs `git` rebuilt for `hurd-amd64` (binary lags at 2.51.0-1 main /
2.53.0-1+hurd.1 unreleased while arch:all `git-man` is at 2.55.0-1). Out of our
control; could take days. A PR-pinned toolchain keeps the lane green meanwhile.
Re-evaluate/remove the pin once the ports buildd catches up.

Seen 2026-08-03 on PR #3470 (runs 30804971205, 30803672544) + unrelated master
run 30809520166. Auto-retry does not help (deterministic, metadata-level).
