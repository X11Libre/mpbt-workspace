---
slug: netbsd-ci-scoped-pkgsrc-x11-sets-mirror-on-github
title: "NetBSD CI: scoped pkgsrc/X11-sets mirror on GitHub (insulate `xserver-build-netbsd` from ftp/cdn.netbsd.org flakes)"
category: active
status: "**Built + PR opened, not merged**"
doc_ref: "**PR #3243** (branch off `rfc/backport-master`, agent clone `_WORK_/xserver-master/agent/netbsd-mirror/xserver`); new `.github/scripts/netbsd/{mirror-conf.sh,sync-pkg-mirror.sh,publish-mirror.sh}` + `.github/workflows/netbsd-pkg-mirror.yml`; hosted as GitHub Release `netbsd-pkgsrc-mirror` in X11Libre/xserver"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Motivated by PR #3225 flake (2026-07-03): `pkg_add: Can't process https://ftp.netbsd.org...: Undefined error: 0`, 3 retries, unrelated to the (Ubuntu-only) diff. Scoped mirror ≈230MB (165MB pkgsrc closure + 65MB X11 sets) vs full pkgsrc 65GB. Weekly cron workflow boots the same `vmactions/netbsd-vm@v1.2.3` (10.1) the build job uses, runs `pkgin -d install` for the authoritative closure (no hand-rolled resolver), builds a **trimmed** `pkg_summary.gz` (subset of the official one, so sizes match), and `gh release upload --clobber`s + prunes stale assets. `install-pkg.sh` now tries the GitHub mirror first, falls back to official on any failure (not a hard cutover). Package list factored into shared `mirror-conf.sh` sourced by both. **Open design Qs flagged in PR:** (1) unverified without a live VM: does pkgin's libfetch follow GitHub's 302 release-asset redirect for `pkg_summary.gz`/`.tgz`? (2) sync-VM-image == build-VM-image assumption for closure matching; (3) optional `libtool`→`libtool-base` swap (~78MB gcc10 drop) left undone to avoid unverifiable build break. Infra blast radius (release hosting + cron cost + staleness) → praetor review before merge.
