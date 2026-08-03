---
title: "CI Hurd lane fails on debian-ports apt dependency conflict (infra flake)"
category: parked
kind: "note"
status: "parked"
noted-by: "Defiant"
since: "2026-08-03"
---

The `xserver-build-hurd` CI lane (hand-rolled QEMU boot against debian-ports
`sid`/`unreleased`) fails before any build step: `apt-get install` of the
toolchain cannot resolve deps —

```
git : Depends: libcurl3t64-gnutls (>= 8.3.0) but it is not going to be installed
git : Depends: git-man (> 1:2.53.0) but it is not going to be installed
meson : Depends: python3-setuptools but it is not going to be installed
pkg-config : Depends: pkgconf (>= 2.5.1-4) but it is not going to be installed
E: Unable to satisfy dependencies. Reached two conflicting assignments:
  1. git:hurd-amd64=1:2.53.0-1+hurd.1 is selected for install
  2. git:hurd-amd64=1:2.53.0-1+hurd.1 Depends git-man (< 1:2.53.0-.)
```

Seen 2026-08-03 on PR #3470 (after the XvMC guards amend). Unrelated to the
code change — pure infra. Auto-retry did not help.

Possible fixes: `apt-get dist-upgrade` first / allow downgrade of git-man, or
pin the VM image's apt state; or relax the toolchain install (`--no-install-recommends`
already used). Lane is inherently flaky (depends on sid/unreleased).
