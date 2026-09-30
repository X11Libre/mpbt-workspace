Title: "xserver: Fix macOS CI break in rootlessScreen.c"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-09-30T11:03:51Z"
Doc-Ref: "—"

Fix leftover fragment from OOM fix in miext/rootless/rootlessScreen.c lines 140-142 that caused undeclared 'data' variable and double-free. Work done in wt/xserver-macos-fix branch.

- 2026-09-30T11:04:01Z Laforge: progress 50% (Created worktree wt/xserver-macos-fix, fixed leftover fragment in miext/rootless/rootlessScreen.c (removed erroneous free()/data assignment), committed and pushed branch to origin. PR ready for review.)
