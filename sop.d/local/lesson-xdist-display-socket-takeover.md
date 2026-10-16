# xdist tests steal each other's X display socket → BrokenPipeError (2026-10-16)

Lesson from fixing the recurring `test/pyxtest` flake that hit
`xserver-build-ubuntu-debug` intermittently (PR #3986).

## Symptom

An unrelated pyxtest file fails with

```
BrokenPipeError: [Errno 32] Broken pipe
test/pyxtest/xclient.py:270: in send_request
    self.sock.sendall(data)
```

Intermittent, different test each time (`test_xi`, `test_xinerama`, …),
and it also reproduces on **master** (run 38760984412), so it is not a
regression of the code under test.

## Root cause

Each test starts its own X server via `-displayfd`, and pytest-xdist runs
several workers (meson several suites) in parallel. Two servers scanning for
a free display number at the same time can **both claim the same number**:
the loser's client connects to the *winner's* server. When the winner is torn
down at the end of its own test, the loser's connection dies mid-test.

Proven by comparing `SO_PEERCRED` of the client socket against the fixture's
server PID: `client connected to PID 3124 instead of the test server (PID
3121) on display :1`. 7/40 sessions hit that, 5/40 the BrokenPipe.

`-displayfd` itself does **not** collide (48 concurrently started servers got
48 distinct numbers) — the race is the start/stop churn, not the count.

## Reproduction technique (works, and matters)

* Build with **`--buildtype=debug`** (the CI lane that shows it).
* Run many **parallel** pytest sessions (`-n auto`, 4 workers), e.g. 10 rounds
  × 4 concurrent sessions, with `MALLOC_PERTURB_` set.
* The default (release) build reproduced **nothing** in 36 sessions → the
  buildtype/timing matters.

## Why the CI log is misleading

`XServerProcess` sends the X server's stderr to a **temp file**
(`/tmp/xserver-*-stderr-*.log`) and never reads it on a normal failure, so a
dead/swapped server leaves **no trace** in the job log. "No crash in the log"
does **not** mean "no crash" here. (Local repro: the temp files were still
there and readable.)

## Fix (PR #3986)

* `flock` around the short display-allocation window (Popen + read
  `-displayfd`) — prevents the takeover; the lock is released as soon as the
  server owns socket + lock file.
* Safety net: record the socket owner PID via `SO_PEERCRED` and fail the
  `xclient` fixture with a precise message instead of an opaque BrokenPipe.

Verified: 0/40 sessions failed after (was 5–7/40), 0 errors over 8 full
`test/pyxtest` runs.

## Nebenlehre: `pkill -f` trifft die eigene Shell

Beim Bauen des Reproduktionsskripts: `pkill -f "hw/vfb/Xvfb"` in einem
`bash -c '...'`-Einzeiler **matcht die eigene Kommandozeile** (der Pattern-
String steht drin) und killt die aufrufende Shell selbst → Befehl bricht
scheinbar grundlos ab/timeoutet. Dieselbe Klasse wie das flottenweite
`pkill -f starfleetctl`-Verbot: `-f` matcht Text, nicht das gemeinte Objekt.
Beim Aufräumen von Testservern **per PID** killen, nie per `pkill -f`.
