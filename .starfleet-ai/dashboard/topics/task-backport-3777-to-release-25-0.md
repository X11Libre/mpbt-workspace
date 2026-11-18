Title: "Backport #3777 to release/25.0: test: fail when a child terminates abnormally"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "LaForge"
Created-By: "Scotty"
Created: "2026-10-01T19:23:25Z"
Doc-Ref: "task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0"

Backport of master PR #3777 to release/25.0

Changes:
- test/tests-common.c: Change exit(exit_code) to exit(EXIT_FAILURE) in run_test_in_child()

This ensures that when a test child is terminated by a signal, the exit status reflects the failure rather than potentially inheriting a success code from a previous test.

Links:
- Batch topic: task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0
- PR: https://github.com/X11Libre/xserver/pull/3797

- 2026-11-17T17:57:45Z LaForge: began work

- 2026-11-17T19:13:43Z LaForge: Update 2026-11-17 (LaForge): PR #4177 OPEN (base release/25.0, head pr/release/25.0-test-fail-when-a-child-terminates-abnormally_2026-11-17_18-11-49 = ceb01b9e90, cherry-pick ce6fa93, 1 Commit Lipinsky, Signed-off-by==1, rev-list origin/release/25.0..HEAD=1, diff 1 file/1 line). PR-Body enthaelt Topic-Slug + Backlinks. CI pull_request auf #4177 laeuft. KEIN Merge (Maintainer).

- 2026-11-18T07:50:27Z LaForge: CI-Nachweis-Luecke bei #3992/#4009 (0 Runs am Head): Retry-Workflow kann nicht helfen (nur fehlgeschlagene Jobs bestehender Runs). close+reopen wurde von Enterprise NICHT freigegeben (external impact, fremde PR-Branches) — keine Ausfuehrung bis McKinley entscheidet (m24012). #4177: label bot-review-wanted gesetzt, CI frisch (abi/drivers/macos pass, ubuntu fail = bekannter signal-logging.c:215 locale-Assert).
