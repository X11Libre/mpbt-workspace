Title: "xserver macOS CI break: rootlessScreen.c leftover fragment"
Category: active
Kind: task
Status: "open"
Created-By: "Laforge"
Created: "2026-09-30T10:59:43Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-xserver-macos-ci-break-rootlessscreen-c-leftover-fragment

Fix macOS CI break on xserver master: miext/rootless/rootlessScreen.c lines 140-142 have leftover fragment from OOM fix (undeclared 'data' variable, free() on newly allocated buffer). Introduced by 924020906e conflict resolution against OOM fix d536dde7b4. Work in own worktree, create PR against master.
