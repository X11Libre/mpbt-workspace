Title: "W0-RM-READONLY remove read-only access option"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-11-14T14:13:16Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-w0-rm-readonly-remove-read-only-access-option

Remove read-only repository access mode: config field/parser/defaults/documentation/tests. All repos read-write; all lifecycle transitions committed locally and pushed. Verified: go build ./... passes, go test ./internal/wormhole/ ./internal/comms/ passes, go test ./internal/task/ passes, 53/53 plugin tests pass.
