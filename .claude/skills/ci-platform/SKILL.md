---
name: ci-platform
description: How the XLibre xserver CI is wired — per-platform lanes, content-addressed deps images (build-if-missing), the hand-rolled GNU/Hurd QEMU boot, the RHEL/AlmaLinux lane, per-lane -Dwerror status, and the scoped NetBSD pkg mirror. Use when debugging a red CI lane, adding a platform, or reasoning about why a lane was skipped.
---

# CI platform lanes (Docker images + VM builds)

The `Build X servers` workflow (`.github/workflows/build-xserver.yml`) fans out one job per
platform. Full detail: **`reference.md`** in this skill's directory (moved out of AGENTS.md).

Run commands from the workspace root (`/home/nekrad/src/xorg/mpbt-workspace`).

## Mental model

- **Content-addressed deps images (build-if-missing).** `gentoo-deps-image` / `ubuntu-deps-image`
  tags are a sha256 of their build inputs; the job `docker manifest inspect`s and only rebuilds when
  the exact tag is missing. `:latest` moves only on master. The per-commit SDK builds `FROM` the
  content-hashed ubuntu base, so a WIP branch uses exactly the deps it defines (no staleness).
- **abi-gated ubuntu/SDK chain:** `ubuntu-deps-image` / `build-sdk-image` / `drivers-build-ubuntu`
  run only on `abi_changed || tag` — a workflow-only PR skips them (gentoo always runs).
- **GNU/Hurd has no vmactions VM — it's a hand-rolled QEMU boot** (`xserver-build-hurd` →
  `.github/scripts/hurd/run-vm-build.sh`). Gotchas: `-M q35` + `ich9-ahci` AHCI (not i440fx IDE);
  gnumach is single-CPU (`-smp` forbidden); add a serial console to `grub.cfg` for `-nographic`;
  `sudo chmod 666 /dev/kvm` (fall back to `-accel tcg`); retry boot ≤3×. Builds Xvfb/Xnest/Xorg/
  Xephyr/GLX (`-Dxvfb -Dxnest -Dxorg -Dxephyr -Dglx`, dri*/glamor/xfbdev/udev/logind off). DRI and
  glamor are fundamentally non-buildable on Hurd (no DRM kernel interface); the one real port task
  is a Hurd kdrive backend for `xfbdev`.
- **RHEL/AlmaLinux lane** (`xserver-build-rhel`): `almalinux:9/10`, EPEL+CRB enabled; do **not**
  list `xorg-x11-font-utils` (not a build dep, aborts `dnf`); RHEL 10 gcc 14 needs the
  `set_sun_path` format-truncation fix for `-Dwerror=true`.
- **`-Dwerror=true` per lane:** on for `ubuntu*`, `rhel`, `solaris`, `gentoo`, `openbsd`; **`alpine`
  stays off** (musl/libbsd `#warning` under `-Werror=cpp` — toolchain quirk, not our bug).
- **NetBSD scoped mirror** (`netbsd-pkgsrc-mirror` release in `X11Libre/xserver`) dodges
  ftp.netbsd.org flakes; `install-pkg.sh` tries the mirror first, falls back to official. Refresh via
  `.github/workflows/netbsd-pkg-mirror.yml` (`workflow_dispatch`). Never hardcode the quarter date in
  the `<rel>/All` 302 redirect — `curl -L` follows it.

## When debugging a red lane

0. **Before trusting a lane's verdict, prove the lane can lie.** A lane status is the
   conclusion of a wrapper, not a measurement of the thing you care about. Verify in the
   *log content* — see "VM lanes: the action does not report the guest's exit code" below.
1. Identify the lane + failure class (build/link, configure/meson, test-phase/XTS).
2. For a WIP branch that "shouldn't have rebuilt deps": check whether the change actually altered the
   deps-image inputs (else the cached content-hashed image is reused — a few-second check).
3. For Hurd: confirm the QEMU attach flags and serial console before assuming a silent hang.
4. For NetBSD: confirm the mirror release is populated (one `workflow_dispatch`) before trusting the
   mirror-first path.

## ccache hides the very output you would count

With ccache in the lane, a **successful** compile prints **no per-file lines**. On a green
run of `xserver-build-dragonflybsd` (run 36763250919):

```
meson install  -> intro-install_plan.json, meson-private/install.dat
compile        -> ccache "total size is 237,948,165  speedup is 1.14"
objects        -> _build/test/tests.p/*.c.o
```

…and `grep -c 'Compiling C'` returns **0**. ninja says nothing because ccache answers every
translation from cache. So **`Compiling C` is not a build marker.** Reading its absence as
"the build never ran" inverts the truth and will make you debug a healthy lane. Count
instead what ccache and meson do emit: `meson install`, `install.dat`, ccache's
`speedup is`, `Build targets in project`, or the `.c.o` paths.

Corollary for any green-check count: **a criterion that is zero on the healthy case is not
a criterion.** Pick it by checking it against a run that is known-good, not against the one
that failed.

## VM lanes: the action does not report the guest's exit code

`vmactions/<os>-vm` runs the step's `run:` over SSH and **loses its exit code**. Observed
2026-10-01 on `xserver-build-dragonflybsd`: the guest shell was killed and the action still
emitted

```
##[end-action ... outcome=success;conclusion=success]
```

A `Killed` line next to an `end-action … success` is the signature. Consequences:

- `conclusion=success` on such a lane does **not** mean the build ran.
- A retry chain keyed on `if: steps.<id>.outcome == 'failure'` ends early on that false
  success, so the retries that would have recovered never run.
- A `Killed` seen right after `tearing down stale VM` / `Domain destroyed` is the
  **teardown** being killed, not the build. Check the two lines before the `Killed` before
  concluding anything about the build.

Affected lanes use `vmactions/*-vm`: dragonflybsd, freebsd, netbsd, openbsd, solaris.
Verified only for dragonflybsd; the others are unexamined and should be assumed broken
until someone counts their logs. `alpine`, `gentoo`, `rhel` run natively and are unaffected.

### `envs:` is a whitelist — an unset variable silently becomes empty

The action forwards **only** the variables listed in `envs:`. `$GITHUB_SHA` is not a default
in the guest. A marker written as `echo "$GITHUB_SHA" > /tmp/marker` from inside such a step
produces an **empty file**, and a later `"" != "$GITHUB_SHA"` comparison then fails the
job — a check that reports failure for a lane that built fine. Any variable the guest must
know has to be named in `envs:` for that step.

### An `if:` without a status function inherits `success()`

`if: steps.x.outcome == 'failure'` is evaluated **and** ANDed with an implicit `success()`.
So a preceding step that fails the job makes every later `if:` false. This silently kills
retry chains: the check that drives the retries must therefore carry `continue-on-error:
true`, and only the final decisive step must not.

## Rollup counts lie twice over

- A release-branch PR whose base lacks the "de-duplicate pipeline runs" condition
  (`123446d11d`) runs the **same matrix twice**, push and pull_request. 78 pending checks
  on such a PR are ~39 real ones. The skip condition keys off the **merge commit**, not the
  branch: `build-xserver.yml` gates `ubuntu-fetch-pkg`, `xserver-build-macos`,
  `xserver-build-cygwin` and `xserver-build-arch` on
  `github.event.pull_request.head.repo.full_name != github.repository`. A PR based on
  `release/*` therefore builds macOS; one based on `master` skips it.
- A matrix job appears once in the rollup per **leg**: the `drivers-build-ubuntu` job
  contributes ~53 check names and is one job.
- Cancellations are not failures. Count `failure` separately from `cancelled`.

## Only `--rebase` is allowed on this repo

`gh pr merge --squash` and `--merge` fail with a GraphQL error
("Squash/Merge commits are not allowed on this repository"). Use `--rebase`. A rebased PR
keeps the commit subject, which is how a rebase-merge is recognised in the log.

## go-xts (go-x11proto) test suite on Xephyr — display-race & byte-order gotchas

Lessons from PR #3122 (".github: use go-x11proto test suite in the CI", 2026-06-25).
`.github/scripts/run-xts-go-xephyr.sh` runs the go-x11proto X11 test suite against an
inner Xephyr.

- **Display-number race → hang:** guessing `XEPHYR_DISPLAY=$((XVFB_DISP + 1))` collides with
  another parallel test's server (meson runs tests with `nproc`). Xephyr (without `-displayfd`)
  fails to bind (`Cannot establish any listening sockets`), but the colliding server's socket
  still satisfies the old wait-loop `for i in $(seq 1 50); [ -S /tmp/.X11-unix/X$N ]` → `$DISPLAY`
  points at the wrong/dead server → the go client hangs until timeout.
  **Fix:** start Xephyr with `-displayfd 4 4>$FIFO` and `read` the chosen number back (like the
  Xvfb host start with fd 3). **Use a single-digit fd** — POSIX sh (dash) parses multi-digit fds
  as literal args. Xephyr/kdrive writes the number only after listeners are up, so the read also
  doubles as a readiness barrier. Reproduce locally: run 3 script copies concurrently, old ~2/3 fail.
- **`+byteswappedclients` needed on the inner Xephyr too:** the X server rejects byte-swapped
  (non-native-endian) clients by default (`Prohibited client endianness`). The xts suite connects
  in BE in some passes, so **every** server it talks to needs `+byteswappedclients` — including
  the inner Xephyr, not just the Xvfb host.
- **Pin sites + byte-order behavior:** go-x11proto is pinned to `PKG_GOXPROTO_REF` in BOTH
  `.github/workflows/conf.sh` and `build-xserver.yml`. v0.0.3's harness spawns its own server via
  `XTS_XSERVER` (both byte orders); only if that fails does it fall back to `$DISPLAY` (LE only).
  `run-xts-go-xephyr.sh` sets `XTS_XSERVER=/nonexistent` to force the `$DISPLAY` fallback → against
  Xephyr only LE runs (BE comes from the xvfb path).

## GH Actions cache & workflow-run gotchas

- **GH Actions cache is branch-scoped AND evictable.** A hit from branch X does NOT mean it exists
  in master's/another PR's scope. `actions/cache` saves ONLY when its restore MISSED. After
  eviction, every lane with `fail-on-cache-miss: true` fails until a full workflow run's fetch-pkg
  misses→downloads→saves.
- **`gh run rerun --failed` CANNOT recover a cache eviction** (skips fetch-pkg). Use a FULL
  `gh run rerun <id>`.
- **The "delete old workflow runs" workflow wipes run history** — old run IDs can 404 later;
  capture what you need while it exists.
- **Master red + PR green pattern:** check whether master's failures share the root cause before
  assuming a PR defect.
