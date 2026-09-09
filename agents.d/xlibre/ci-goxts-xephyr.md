---
slug: xlibre/ci-goxts-xephyr
title: "CI: go-xts Xephyr test gotchas"
---

# go-xts (go-x11proto) CI test on Xephyr — display-race & byte-order gotchas

Lessons from the PR #3122 repair (".github: use go-x11proto test suite in the CI",
2026-06-25).

## The display-number race (the hang)

`.github/scripts/run-xts-go-xephyr.sh` hangs in CI when it guesses
`XEPHYR_DISPLAY=$((XVFB_DISP + 1))`. meson runs tests in parallel (`nproc`), so the
guess collides with another test's server: Xephyr (without `-displayfd`) fails to
bind (`Cannot establish any listening sockets`), but the colliding server's socket
still satisfies the old wait-loop `for i in $(seq 1 50); [ -S /tmp/.X11-unix/X$N ]`
→ `$DISPLAY` points at the wrong/dead server → the go client hangs until timeout.

**Fix:** start Xephyr with `-displayfd 4 4>$FIFO` and `read` the chosen number back
(exactly like the Xvfb host start does with fd 3). **Use a single-digit fd** — POSIX
sh (dash) parses multi-digit fds as literal args. Xephyr/kdrive writes the number
only after listeners are up, so the read also doubles as a readiness barrier.
Reproduce locally: run 3 script copies concurrently, grep for `Cannot establish`
(old ~2/3 fail; new 0/3).

## Two related gotchas from the same PR

- **`+byteswappedclients` is needed on the inner Xephyr too.** The X server rejects
  byte-swapped (non-native-endian) clients by default (`Prohibited client endianness`).
  The xts suite connects in BE in some passes, so **every** server it talks to needs
  `+byteswappedclients` — including the inner Xephyr, not just the Xvfb host.
- **Pin sites + byte-order behavior.** go-x11proto is pinned to `PKG_GOXPROTO_REF` in
  BOTH `.github/workflows/conf.sh` and `build-xserver.yml`. v0.0.3's harness spawns its
  own server via `XTS_XSERVER` (both byte orders); only if that fails does it fall back
  to `$DISPLAY` (LE only). `run-xts-go-xephyr.sh` sets `XTS_XSERVER=/nonexistent` to
  force the `$DISPLAY` fallback → against Xephyr only LE runs (BE comes from the xvfb path).