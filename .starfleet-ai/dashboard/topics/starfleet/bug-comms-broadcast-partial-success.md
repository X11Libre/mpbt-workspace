Title: "BUG: comms broadcast partial success (no atomicity)"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "Rosetta"
Created-By: "Enterprise"
Created: "2026-10-15T13:31:58Z"
Doc-Ref: "—"

internal/comms/commands.go:166: broadcast writes per-recipient copies without atomicity. If one write fails, earlier copies remain. Should write to temp and move atomically, or track which succeeded and rollback on failure.
