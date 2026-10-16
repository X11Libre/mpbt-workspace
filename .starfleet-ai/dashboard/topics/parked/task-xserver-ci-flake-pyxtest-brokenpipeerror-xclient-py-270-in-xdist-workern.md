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
