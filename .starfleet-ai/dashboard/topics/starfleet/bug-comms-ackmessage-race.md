Title: "BUG: comms ackMessage race condition (no lock)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-15T13:32:21Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/bug-comms-ackmessage-race

internal/comms/commands.go:568-587: ackMessage() moves unseen->seen without holding lock. Concurrent calls (e.g. from dispatchAck and manual ack) can corrupt state. DoAck takes lock but ackMessage doesn't. Fix: ackMessage should take lock, or DoAck should hold lock during ackMessage call.
