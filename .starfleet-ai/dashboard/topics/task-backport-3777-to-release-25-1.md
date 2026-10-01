---
Title: "Backport #3777 to release/25.1: test: fail when a child terminates abnormally"
Category: active
Kind: task
Status: open
Assigned-To: "Scotty"
Created-By: "Scotty"
Created: 2026-10-01T19:28:56Z
Doc-Ref: "task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0"
PR: 3798
Commit: adc5f461d0
Branch: release/25.1
---

Backport of master PR #3777 to release/25.1

Changes:
- test/tests-common.c: Change exit(exit_code) to exit(EXIT_FAILURE) in run_test_in_child()

This ensures that when a test child is terminated by a signal, the exit status reflects the failure rather than potentially inheriting a success code from a previous test.

Links:
- Batch topic: task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0
- PR: https://github.com/X11Libre/xserver/pull/3798
