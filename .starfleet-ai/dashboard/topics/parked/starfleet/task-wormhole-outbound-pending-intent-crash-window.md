Title: "Outbound wormhole exactly-once: pending-intent before transport publish (parked)"
Category: parked
Kind: task
Status: "open"
Created-By: "LaForge"
Created: "2026-11-15T14:26:12Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/starfleet/task-wormhole-outbound-pending-intent-crash-window

Parked per Enterprise m23243 (out of W0-134 scope, follow-up). Finding (LaForge review, report 1794750874364488862 / comms m23238): postAs publishes remote FIRST (internal/comms/commands.go:172 -> routing.go:213 -> wormhole/comms_transport.go:27 -> messages.go:99 random newMessageID -> Spool.Publish commit+push) and only afterwards writes the local outbox record with a plain os.WriteFile (commands.go:227 — no tmp/fsync/rename/dirsync). Crash in that window => remote holds w0-X, local has no record: reply correlation dangles (reply_to unknown locally) and a retry creates a NEW random ID => duplicate remote message, both imported inbound (different external IDs). Severity: medium. Sound design: persist a pending-intent (message ID + payload hash, state=pending) atomically+durably BEFORE calling the transport (tmp+fsync+rename+dirsync pattern of comms_external.go:142-203), mark sent after publish, and on startup resume pending intents by re-publishing with the SAME ID — Spool.Publish is already idempotent for identical bytes and fails closed on differing bytes (spool.go:320-324). Also make the outbox record write itself atomic+durable. Owner: Voyager/Discovery (comms outbox scope). Evidence: commands.go:146-231, routing.go:213-226, comms_transport.go:27, messages.go:99-106, spool.go:299-346; tests on inbound side: TestPostExternalCrash*, TestPostExternalConcurrentCalls (comms_external_test.go).
