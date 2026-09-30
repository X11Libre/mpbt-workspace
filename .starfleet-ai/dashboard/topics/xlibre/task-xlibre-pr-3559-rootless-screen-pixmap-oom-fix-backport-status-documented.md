Title: "xlibre: PR #3559 rootless screen pixmap OOM fix - backport status documented"
Category: xlibre
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-30T09:37:40Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: xlibre/task-xlibre-pr-3559-rootless-screen-pixmap-oom-fix-backport-status-documented

Document backport status of PR #3559 (rootless: Keep the screen pixmap header consistent with its allocation) across release lines.

Findings:
- PR #3559 merged in xserver-master as commit 2624b548ba (2026-08-16, Jeremy Huddleston Sequoia)
- xserver-25.2: NO direct backport of PR #3559 commit, BUT equivalent fix exists:
  - Commit b9a6330267 (2026-07-07, Enrico Weigelt): 'rootless: fix dangling screen pixmap on RootlessUpdateScreenPixmap() OOM'
  - Same root cause, same fix strategy (allocate temp first, then swap)
  - Different commit, different author, earlier date
- xserver-25.1: Direct backport exists as commit d44551d41d (identical to master commit)
- xserver-25.0: Direct backport exists as commit 0b1de8910d (identical to master commit)

Conclusion: 25.2 is protected against this issue via a different but functionally equivalent fix. No action needed for 25.2.
