# go-xts (go-x11proto) CI test on Xephyr — display-race & byte-order gotchas

Lessons from the PR #3122 repair (".github: use go-x11proto test suite in the CI",
2026-06-25). Lives here (shared, version-controlled) rather than per-user Claude
memory because it's project/operational knowledge the whole team benefits from.

## The display-number race (the hang)

`test/scripts/run-xts-go-xephyr.sh` go-xts test hangs in CI (300s / 1200s timeouts)
when it launches Xephyr with a **guessed** display number
`XEPHYR_DISPLAY=$((XVFB_DISP + 1))`. meson runs the test suite in parallel (`nproc`),
so the guessed number collides with another test's server: Xephyr (started **without**
`-displayfd`) fails to bind (`Cannot establish any listening sockets`), but the
colliding server's socket still satisfies the old wait-loop
`for i in $(seq 1 50); [ -S /tmp/.X11-unix/X$N ]`, leaving `$DISPLAY` pointed at the
wrong/dead server → the go client hangs until timeout.

**Why:** atomic free-display selection is the only race-safe way; `+1` is not.

**Fix / how to apply:** start Xephyr with `-displayfd 4 4>$FIFO` and `read` the chosen
number back (exactly like the Xvfb host start already does with fd 3). Use a
**single-digit** fd — POSIX sh (dash) parses multi-digit fds in redirections as literal
args. Confirmed: Xephyr/kdrive honors `-displayfd` (`os/connection.c` writes the number
only after listeners are up, so the read also doubles as a readiness barrier).
Reproduce the race locally by running 3 copies of the script concurrently and grepping
for `Cannot establish` (old: ~2/3 fail; new: 0/3).

## Two related gotchas from the same PR

- **`+byteswappedclients` is needed on the inner Xephyr too.** The X server rejects
  byte-swapped (non-native-endian) clients by default (`Prohibited client endianness`).
  The go-x11proto xts suite connects in BE in some passes, so **every** server it talks
  to needs `+byteswappedclients` — including the inner Xephyr, not just the Xvfb host.
  (dix option, `os/utils.c`.)

- **go-x11proto pin sites + byte-order behavior.** go-x11proto is pinned to
  `PKG_GOXPROTO_REF` in BOTH `.github/scripts/conf.sh` and
  `.github/workflows/build-xserver.yml`. v0.0.3's harness spawns its own server via
  `XTS_XSERVER` and then exercises *both* byte orders; only if that spawn fails does it
  fall back to `$DISPLAY` and run **little-endian only**. `run-xts-go-xephyr.sh` sets
  `XTS_XSERVER=/nonexistent` to force the `$DISPLAY` fallback → against Xephyr only LE
  runs (BE coverage comes from the xvfb path).
