---
slug: xdotool-windowkill-in-terminal-demo-testing-killed-the-shared-lxterminal
title: "`xdotool getactivewindow windowkill` in go-x11proto terminal-demo testing killed the whole shared lxterminal (all ships) — 2026-07-06"
category: parked
noted_by: "Enterprise, 2026-07-06, root-caused from transcript after the fleet-wide crash"
since: "2026-07-06"
---

**Incident:** ~20:34:43 local, an agent working on go-x11proto's `demo/terminal` (testing a
double-line box-drawing fix for `mc`-style rendering, `tk/term/parser.go` etc., branch `staging`)
ran, to kill its previous test-window instance before rebuilding:

```
DISPLAY=:0.0 xdotool getactivewindow windowkill 2>&1 || true
pkill -f terminal-demo 2>&1 || true
```

`getactivewindow windowkill` acts on whatever window currently has X focus on the **real, shared**
display — not scoped to the test window at all. At that moment focus was apparently on the shared
`lxterminal` window hosting every ship's tab, not the demo window, so it force-killed lxterminal
itself, taking down every ship's session simultaneously (all ships showed `clear` events within
~10s of each other on the bus). Confirmed from the session's own transcript
(`~/.claude/projects/-home-nekrad-src-xorg-mpbt-workspace/6ea2d3bd-*.jsonl`, the Bash call itself
came back "Exit code 144" — its own controlling terminal died mid-command).

**Rule going forward:** never kill an X window by "whatever's currently active/focused" in any
test/demo script or ad-hoc command — that's shared, ambient global state on a real display also
hosting the live fleet. Always scope by PID (own child process) or by window
name/class/title (`xdotool search --name <specific-title> windowkill`, or better, just track the
demo's own PID from `go build -o ... && ./bin & pid=$!` and `kill "$pid"`), never by "active
window". The `pkill -f terminal-demo` line right after was already the correct/safe approach on
its own — the `xdotool windowkill` line was redundant *and* the actual cause; just drop it.

**Recovery, 2026-07-06 (Enterprise):** fleet relaunched (ships: Agamemnon, Constellation,
Endeavour, Farragut, Intrepid, Pegasus + Enterprise). No orphaned `pr-claim` locks found; git
worktree `mpbt-clone.lock`/meson `.lock` files present are normal per-worktree flock files, not
evidence of anything stuck. Interrupted work recovered: Constellation's m0108 (`agent-run`
absolute-path-to-claude fix) was already validated + committed
(b514ec4). The go-x11proto `staging`-branch double-line box-drawing fix was mid-verification
(build/vet/test all green, final live demo re-check interrupted by the crash) — uncommitted in
`_WORK_/go-x11proto/sources/xlibre/go-x11proto` (`tk/term/parser.go`, `parser_test.go`, `term.go`,
new `term_test.go`), handed back to the fleet to finish safely (see agent-bus m0118+).
