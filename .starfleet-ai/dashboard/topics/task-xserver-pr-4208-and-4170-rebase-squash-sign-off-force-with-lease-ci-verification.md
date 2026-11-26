Title: "Xserver PR #4170 regression-test repair; PR #4208 security backport merged"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-23T09:12:44Z"
Doc-Ref: "—"

Superseded 2026-11-26: PR #4208 is already merged. Only PR #4170 remains active; do not rebase/squash/force-push until the shared-helper blocker is fixed and reviewed. Follow-up: w0-20261126T080000Z-voyager-pr4170-helper-bounds-01.

- 2026-11-23T09:19:33Z Voyager: progress 10% (Received scope correction for #4170 (m24980) - pyxtest testcase only, revert production code changes. Starting investigation of current PR state and target branches.)

- 2026-11-23T19:07:05Z Voyager: progress 50% (PR #4170 repair started: will fix pyxtest regression test to exercise 36-valuator boundary (CVE-2026-109093), remove stale test_xv.py registration, replace 'in' operator with .contains(), then push and run CI)

- 2026-11-25T15:38:44Z Voyager: progress 75% (meson.build fixes applied and pushed to PR #4170: removed test_xv.py, fixed 'in' -> .contains(). CI triggered on push. Test logic blocker remains: pyxtest cannot create device with >=42 axes to exercise MAX_VALUATORS (36) boundary. Awaiting direction on test approach.)

- 2026-11-25T15:46:06Z Voyager: progress 85% (PR #4170: meson.build fixes pushed (removed test_xv.py, fixed 'in' -> .contains()). CI running on GitHub - several jobs in progress (RHEL 9, abi-changes-check, gentoo-deps-image passed). Test logic blocker: pyxtest cannot create device with >=42 axes to exercise MAX_VALUATORS (36) boundary. PR #4208 doesn't exist - CVE-2026-50264 backport is on branch 'backport/cve-2026-50264-252' but no PR created yet. Need direction: (1) create PR for CVE backport to release/25.2, (2) test approach for PR #4170 (Option A: meson-only + document; Option B: add XIChangeHierarchy builder; Option C: alternative).)


- 2026-11-26 ChatGPT independent live review: PR #4208 exists and is merged (CVE-2026-50264, release/25.2); sibling backports #4200 (release/25.1) and #4202 (release/25.0) are also merged. This is the DRI2 off-by-one fix, not the XTest CVE.
- CVE-2026-109093 issue #4134 records fix commits on master and release/25.0, release/25.1 and release/25.2. GitHub compare confirms each cited fix commit is an ancestor of its target branch. The duplicate PRs #4189, #4190, #4161 and #4172 were closed without merge; do not recreate them.
- PR #4170 is OPEN and intended as a regression-test repair, but the published diff also extracts a production helper and routes ProcXTestFakeInput() through it; it is therefore not behavior-neutral and must be reviewed as production code. Current head 4a269bf6767c158d26fb8759797386c4abcbdfbb, base master 0b5e2dd6ef70dc366f2357db655efcbd7adb7cb7. Exact-head checks: 50 total, 38 success, 12 skipped, 0 failed; Build X servers succeeded. No APPROVED review exists; owner has one COMMENTED review and X11Libre/dev is requested.
- Independent diff review found a BLOCKER in XTestCopyValuators(): ProcXTestFakeInput passes the already-advanced destination base and also cumulative numValuators, while the helper adds both when writing. The second record in a normal 6+6 chain therefore writes at index 12 instead of 6. Its stack bound also ignores cumulative, so a later record can pass the check and write beyond MAX_VALUATORS. Current unit tests do not cover a multi-record chain.
- Follow-up task with exact reproduction, correction contract and required regression tests was published to mail/Voyager/new as w0-20261126T080000Z-voyager-pr4170-helper-bounds-01 (Wormhole commit bea9467cfc241105d2641afdaf9bd95f0d48b258). Publication is verified; no claim yet that Voyager imported or acknowledged it.
- No local ship worktree was available to ChatGPT; no local test commands were run. Keep PR open and do not rebase/squash/force-push/merge until Voyager acknowledges, fixes the helper and provides exact-head local test evidence.
