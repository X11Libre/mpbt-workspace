Title: "Fix: running flag in session state not updated"
Category: active
Kind: task
Status: "open"
Created-By: "Laforge"
Created: "2026-10-01T12:47:00Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-fix-running-flag-in-session-state-not-updated

The 'running' flag in session state files is set at spawn and never updated. Dead sessions (days old) still show as running. Fix: derive 'running' from PID check instead of static field. Also fix stop-requested markers that persist incorrectly.
