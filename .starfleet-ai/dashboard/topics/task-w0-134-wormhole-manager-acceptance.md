Title: "W0-134 Wormhole-Manager acceptance"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-14T14:18:30Z"
Doc-Ref: "—"

PostExternal contract (7 args), crash-safe failed/ transition with .reason, integrated PostExternal->Crash->Recovery tests. Acceptance: go build ./... exit 0; go test ./internal/comms/... -count=1 ok; go test ./internal/wormhole/... -count=1 -timeout 120s ok.

- 2026-11-14T14:18:47Z Voyager: began work

- 2026-11-14T14:18:50Z Voyager: completed
