Title: "xserver: Fix macOS CI break in rootlessScreen.c"
Category: active
Kind: task
Status: "open"
Created-By: "Laforge"
Created: "2026-09-30T11:03:51Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-xserver-fix-macos-ci-break-in-rootlessscreen-c

Fix leftover fragment from OOM fix in miext/rootless/rootlessScreen.c lines 140-142 that caused undeclared 'data' variable and double-free. Work done in wt/xserver-macos-fix branch.
