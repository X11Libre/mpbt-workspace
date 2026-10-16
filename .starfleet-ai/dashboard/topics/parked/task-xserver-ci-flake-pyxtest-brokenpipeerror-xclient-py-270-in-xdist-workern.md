Title: "xserver CI flake: pyxtest BrokenPipeError (xclient.py:270) in xdist-Workern"
Category: parked
Kind: task
Status: "open"
Created-By: "Defiant"
Created: "2026-10-16T10:39:31Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/task-xserver-ci-flake-pyxtest-brokenpipeerror-xclient-py-270-in-xdist-workern

Ausgepraegt in PR #3985 run 38885645978 (ubuntu-debug): 2 FAILED pyxtest test_xi.py mit 'BrokenPipeError: [Errno 32] Broken pipe' bei xclient.py:270 send_request (sock.sendall) — die X-Verbindung war schon geschlossen, waehrend der Test schrieb. GLEICHE Fehlerklasse GEMESSEN auf MASTER (push-Run 38760984412, 2026-10-15, vor diesem Patch!): FAILED test_xinerama.py::TestPseudoramiXGetState::test_xinerama_get_state_window_swapped[xvfb], identisch bei xclient.py:270; dort beide Flakes gleichzeitig (2/35 xvfb display info FAIL + 29/35 pyxtest test_xinerama FAIL). Nicht deterministisch: derselbe SHA f31d9cedd6 verlief im Parallellauf 38885637427 komplett gruen. Also VORBEHANDENER, unabhaengiger pyxtest-Harness-Flake, NICHT vom is_parallel-Patch verursacht. Kein Server-Crash (kein Assert/SEGV im Log) — der Server hat die Verbindung geschlossen. Wird durch xdist '-n auto' (4 Worker) ausgeloesst. Eigenstaendiger Fix, eigener PR (eine Sache pro Commit).

## Root cause (2026-10-16, Defiant) + Fix

**Mechanismus:** Der Client verbindet auf `/tmp/.X11-unix/X<n>`, aber dieses Socket gehoert dem X-Server eines ANDEREN parallel laufenden Tests (Display-Socket-Takeover beim Start/Stop-Churn mehrerer `-displayfd`-Server). Wenn der fremde Server am Ende seines Tests abgeraeumt wird, stirbt die Verbindung mitten im Test -> `BrokenPipeError` in einem unzusammenhangenden Test. Kein Server-Crash; der Fixture-eigene Server lebt (Exit-Code sauber).

**Beleg:** SO_PEERCRED-PID des Sockets gegen die Fixture-Server-PID geprueft, `--buildtype=debug`, 4 pytest-xdist-Worker, 40 parallele pytest-Sessions von test_xi.py: 7x "client connected to PID X instead of the test server (PID Y)", 5x BrokenPipeError. `-displayfd` selbst kollidiert NICHT (48 gleichzeitige Server, keine Duplikate) — die Race ist der Start/Stop-Churn. In CI ist der Server-stderr in einer Tempdatei -> Ursache unsichtbar.

**Fix (lokal, Branch `wt/pyxtest-display-lock`, Commit `87271b6621`, auf origin/master, nicht gepusht):** flock um das Display-Allokations-Fenster (Verhinderung) + SO_PEERCRED-Check im xclient-Fixture (klare Fehlermeldung statt kryptischem BrokenPipe). Nach dem Fix 0/40 Sessions fehlerhaft + 0 Fehler ueber 8 volle test/pyxtest-Laeufe. Freigabe fuer Push/PR offen.

**PR #3986 (offen, Praetor-freigegeben):** https://github.com/X11Libre/xserver/pull/3986 — Branch pr/master-test-pyxtest-..._2026-10-16_14-26-51, Commit 2f21cd5a21, 3 Dateien. CI: 35 pending / 0 fail zum Start.
