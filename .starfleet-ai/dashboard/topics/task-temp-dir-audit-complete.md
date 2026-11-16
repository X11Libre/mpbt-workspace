Title: "Temp dir audit complete"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-11-16T13:48:47Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-temp-dir-audit-complete

READ-ONLY runtime audit of temp/permission handling complete. Target policy: per-ship TMPDIR/TMP/TEMP = _WORK_/tmp/ship-<id>. Root cause: terminal ships get external_directory '**' = 'ask' + no TMPDIR redirect. Current behavior documented with exact code paths (launch.go:689, 1047, 1409). Option 1 implementation plan with exact changes. Hard-coded /tmp not found in production. Test commands documented. Dashboard: task-audit-complete-temp-directory-permission-policy
