Title: "Xserver PR #4208 and #4170 - rebase, squash, sign-off, force-with-lease, CI verification"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-23T09:12:44Z"
Doc-Ref: "—"

ChatGPT directive m24976: rebase both PRs, squash to one commit each, add Signed-off-by, force-with-lease update, rerun CI, report results

- 2026-11-23T09:19:33Z Voyager: progress 10% (Received scope correction for #4170 (m24980) - pyxtest testcase only, revert production code changes. Starting investigation of current PR state and target branches.)

- 2026-11-23T19:07:05Z Voyager: progress 50% (PR #4170 repair started: will fix pyxtest regression test to exercise 36-valuator boundary (CVE-2026-109093), remove stale test_xv.py registration, replace 'in' operator with .contains(), then push and run CI)
