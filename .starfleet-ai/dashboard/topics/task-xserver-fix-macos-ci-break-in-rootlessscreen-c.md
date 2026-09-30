Title: "xserver: Fix macOS CI break in rootlessScreen.c"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-09-30T11:03:51Z"
Doc-Ref: "—"

Fix leftover fragment from OOM fix in miext/rootless/rootlessScreen.c lines 140-142 that caused undeclared 'data' variable and double-free. Work done in wt/xserver-macos-fix branch.

- 2026-09-30T11:04:01Z Laforge: progress 50% (Created worktree wt/xserver-macos-fix, fixed leftover fragment in miext/rootless/rootlessScreen.c (removed erroneous free()/data assignment), committed and pushed branch to origin. PR ready for review.)

- 2026-09-30T11:04:34Z Laforge: progress 100% (Fixed leftover fragment in miext/rootless/rootlessScreen.c: removed erroneous free()/data assignment lines 140-142 that were introduced during conflict resolution of PR #3559 against OOM fix d536dde7b4. Work done in wt/xserver-macos-fix branch, commit 5a6d453d3d, pushed to origin as wt/xserver-macos-fix. PR ready for review. 25.0/25.1/25.2 unaffected.)

- 2026-09-30T11:05:44Z Laforge: progress 100% (Task completed: Fix is correct and matches Defiant's PR (fa79d183d4) and Enterprise's commit (dba5952447). As requested, no PR opened; fix sits in worktree wt/xserver-macos-fix commit 5a6d453d3d. Ready for integration.)
