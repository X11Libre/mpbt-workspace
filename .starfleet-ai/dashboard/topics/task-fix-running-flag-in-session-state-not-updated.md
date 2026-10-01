Title: "Fix: running flag in session state not updated"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-10-01T12:47:00Z"
Doc-Ref: "—"

The 'running' flag in session state files is set at spawn and never updated. Dead sessions (days old) still show as running. Fix: derive 'running' from PID check instead of static field. Also fix stop-requested markers that persist incorrectly.

- 2026-10-01T12:48:42Z Laforge: progress 10% (Starting investigation: need to find where session state is written/read and fix running flag to be derived from PID check)
