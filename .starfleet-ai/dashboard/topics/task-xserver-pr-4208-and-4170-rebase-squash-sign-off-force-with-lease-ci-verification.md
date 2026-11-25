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

- 2026-11-25T15:38:44Z Voyager: progress 75% (meson.build fixes applied and pushed to PR #4170: removed test_xv.py, fixed 'in' -> .contains(). CI triggered on push. Test logic blocker remains: pyxtest cannot create device with >=42 axes to exercise MAX_VALUATORS (36) boundary. Awaiting direction on test approach.)

- 2026-11-25T15:46:06Z Voyager: progress 85% (PR #4170: meson.build fixes pushed (removed test_xv.py, fixed 'in' -> .contains()). CI running on GitHub - several jobs in progress (RHEL 9, abi-changes-check, gentoo-deps-image passed). Test logic blocker: pyxtest cannot create device with >=42 axes to exercise MAX_VALUATORS (36) boundary. PR #4208 doesn't exist - CVE-2026-50264 backport is on branch 'backport/cve-2026-50264-252' but no PR created yet. Need direction: (1) create PR for CVE backport to release/25.2, (2) test approach for PR #4170 (Option A: meson-only + document; Option B: add XIChangeHierarchy builder; Option C: alternative).)
