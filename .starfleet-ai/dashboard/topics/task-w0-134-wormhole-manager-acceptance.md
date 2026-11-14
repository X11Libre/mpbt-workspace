Title: "W0-134 Wormhole-Manager acceptance"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-11-14T14:18:30Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-w0-134-wormhole-manager-acceptance

PostExternal contract (7 args), crash-safe failed/ transition with .reason, integrated PostExternal->Crash->Recovery tests. Acceptance: go build ./... exit 0; go test ./internal/comms/... -count=1 ok; go test ./internal/wormhole/... -count=1 -timeout 120s ok.
