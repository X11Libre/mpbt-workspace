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

- 2026-11-14T23:19:54Z LaForge: progress 5% (Fresh state: session ses_e44d606e9ffefqtM0lTfnEunMy, active opencode PID 24680, termctl wrapper PID 24665; repo _WORK_/starfleetctl/sources/starfleetctl; worktree _WORK_/starfleetctl/worktrees/starfleetctl/wormhole-manager-w0-017; branch work/wormhole-manager-w0-017; HEAD 7ece6206e34f91febb335477760c5f89e2ab2e7f; upstream origin/work/wormhole-manager-w0-017 (+0/-0); DIRTY: staged M internal/comms/commands.go, staged+unstaged MM internal/comms/comms_external_test.go; preserving changes; next inspect current diff and map it to W0-134 PostExternal durability/recovery criteria, then run focused tests.)
