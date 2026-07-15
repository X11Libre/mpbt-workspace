---
slug: agent-bus-periodic-heartbeat-refresh
title: "agent-bus: periodic heartbeat refresh (avoid false-dead ships past BUS_TTL)"
category: active
status: "Done, 2026-07-06 (Constellation), directive m0086"
doc_ref: "`scripts/agent-bus` (`do_touch`), `scripts/agent-bus-monitor-loop`, `mpbt-hq/starfleetctl@97f8c19` (`DoTouch` + bridged allowlist)"
---

**Problem** (hit live by Enterprise/Pegasus, 2026-07-06): a ship's heartbeat only updates when it
actively calls `agent-bus status`. A ship deep in a long task (e.g. waiting on a delegated
background agent) without touching `agent-bus` in between falls out of `$BUS_TTL` (15min default)
and shows as dead/pruned on the board, even though the session is very much alive.

**Fix:** a new `agent-bus touch` subcommand refreshes *only* the timestamp of my own last-known
heartbeat, reusing whatever state/note was already posted — no new text needed, no state change.
`scripts/agent-bus-monitor-loop` (already armed every session for inbox-watching) now also calls
it every `$HEARTBEAT_INTERVAL` (default 300s, well under the 15min TTL) as a side effect of its
existing poll loop, rather than arming a second Monitor-tool loop per session — reuses what's
already continuously running.

**Race-safety (the actual design constraint m0086 called out):** `touch` does **not** cache a
state+note value anywhere — in this loop, in the daemon, nowhere. Every refresh re-reads whatever
is *currently* on disk for the agent's own status file, under the same lock a real `status` write
uses, and rewrites only the timestamp fields. If a real `agent-bus status <newstate>` call happened
between two refresh cycles, the next touch picks up that new value (the file is the single source
of truth) — there is no stale cached copy anywhere that could ever clobber a fresh real post.
Deliberately does **not** log an event: a pure timestamp bump every few minutes forever isn't a
state transition worth an audit-trail entry, and would clutter `events.log` with noise
indistinguishable from real status changes.

**Applies to all ships**, not just Enterprise — it's a plain `agent-bus`/`agent-bus-monitor-loop`
change, and every session already arms the monitor loop per the standing `SessionStart` convention.

**Both implementations ported** (bash is authoritative/production; Go mirrors it for the
`bridged` daemon prototype and future cutover):
- Bash: `do_touch()` in `scripts/agent-bus`, dispatched via the `touch` case; wired into
  `scripts/agent-bus-monitor-loop`'s existing 2s poll loop with a `last_heartbeat`/`$now` elapsed-time
  check (`|| true` so a transient touch failure can't kill the persistent Monitor-tool loop).
- Go: `Bus.DoTouch()` in `internal/agentbus/commands.go`, wired into `Run()`'s switch and into
  `bridged`'s `allowedAgentBusSubcommands` allowlist (quick, non-blocking — same risk class as
  `status`/`clear`/`inbox`/`ack`). Three new tests (`touch_test.go`): no-op with nothing posted yet;
  refreshes timestamp while preserving every other field; and the specific race-safety property —
  a real `DoStatus` call between two touch cycles is what gets refreshed, never something older
  (proves re-read, not cache).

**Verified end to end against the real production bus** with a disposable, clearly-marked test
agent ID (`ZZZ-Heartbeat*`, cleaned up immediately after) — confirmed the timestamp advances on the
expected interval while state/note/pid/handle/project stay identical, and no spurious `events.log`
entries appear from the refresh itself. Debugging note for future readers: testing this via a
custom scratch `$BUS_DIR` export is misleading — `agent-bus-monitor-loop` intentionally hardcodes
its own `BUS_DIR="$ROOT/_WORK_/agent-bus"` (correct for its real job, always the one true production
bus) rather than respecting a `$BUS_DIR` override, so a `touch` invoked from inside the loop
silently targets the real bus regardless of any env-var override in the calling shell — not a bug,
but easy to misread as one (cost real debugging time this session before realizing it was a test
methodology issue, not a defect in `do_touch`/`DoTouch` themselves).

**Not addressed here:** the separate, currently HIGHEST-PRIORITY `agent-bus-monitor-loop`/
`fleet-watch` bug (directive m0087) — the **Go port** of these two loops reliably misses live
messages arriving *after* the Claude-Code Monitor tool starts them (only the initial backlog is
detected), suspected `os.Stdout` buffering difference between a Monitor-tool-launched process and a
terminal-launched one. That bug blocks the *Go* monitor-loop from ever being cutover-eligible: it
has no bearing on this heartbeat feature, which was built directly into the **bash** loop (the one
actually armed in production today) and additionally ported to the Go `agentbus`/`bridged` packages
for parity/future use, not for any current production Go monitor-loop path.
