Title: "Backport #3777 to release/25.1: test: fail when a child terminates abnormally"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "LaForge"
Created-By: "Scotty"
Created: "2026-10-01T19:28:56Z"
Doc-Ref: "task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0"

Backport of master PR #3777 to release/25.1

Changes:
- test/tests-common.c: Change exit(exit_code) to exit(EXIT_FAILURE) in run_test_in_child()

This ensures that when a test child is terminated by a signal, the exit status reflects the failure rather than potentially inheriting a success code from a previous test.

Links:
- Batch topic: task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0
- PR: https://github.com/X11Libre/xserver/pull/3798

- 2026-11-17T19:13:47Z LaForge: Update 2026-11-17: aktueller PR ist #3992 (alt #3798 CLOSED unmerged). Head ce6fa93: 1 Commit Lipinsky, sign-off 1, bot-review-passed. PR-Body ergaenzt um Topic task-backport-3777-to-release-25-1 + Backlinks (#4177 25.0, #4009 25.2). 0 CI-Runs am Head (gelöscht) — Re-Trigger angefragt via PR-Kommentar. Warte auf CI + Maintainer-Merge.
