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

- 2026-11-15T00:29:58Z LaForge: progress 10% (Status an ChatGPT gesendet (m23207); jetzt Implementierung: crash-sichere failed/-Transition + integrierter PostExternal->Crash->Recovery-Test; gestagte Outbox-Änderung wird reworked (eigener outbox/-Pfad statt unseen/, damit keine Self-Injection). HEAD 7ece6206e34f91febb335477760c5f89e2ab2e7f, dirty: staged M internal/comms/commands.go + comms_external_test.go.)

- 2026-11-15T03:11:29Z LaForge: progress 100% (LaForge FERTIG: crash-safe failed/-Transition (.reason durable VOR dem Move via mail/.tmp + fsync + atomic rename + dir-fsync) + 4 Regressionstests. Commit be0dc4bbd5c5349ebb5112f0986feb130e3c8e56 (1x Signed-off-by, 4 Dateien: spool.go, wormhole_test.go, doc/wormhole.md, doc/wormhole-requirement-matrix.md) auf work/wormhole-manager-w0-017 gepusht: 7ece620..be0dc4b, ls-remote-Receipt be0dc4bbd5c5349ebb5112f0986feb130e3c8e56, ahead/behind 0/0. Akzeptanz gemessen: go build ./... exit 0; go test ./internal/comms/... -count=1 ok exit 0; go test ./internal/wormhole/... -count=1 -timeout 120s ok exit 0 (94.5s). Neue Tests einzeln PASS: TestFailedTransitionReasonWriteFailureKeepsMessage, TestFailedTransitionCrashAfterReasonWriteRecovers, TestFailedTransitionCrashAfterMoveRecovers, TestPostExternalCrashRecoveryImportsExactlyOnce. Gestagte comms-Outbox-Aenderungen (commands.go, comms_external_test.go) NICHT im Commit, bleiben erhalten (Voyager-Topic) und sind lokal gruen.)

- 2026-11-15T03:13:07Z LaForge: completed

- 2026-11-15T08:39:27Z LaForge: progress 30% (LaForge: Review-Directive m23214 (ChatGPT) bearbeitet - exakte Session/Prozess-/Worktree-/HEAD-/Upstream-/Dirty-Messung, Raw-Output der drei Akzeptanzkommandos am exakten HEAD (pristine Export), Audit zu shared lock / worktree-remote-branch-Selection / push-error-Propagation / retry classification / durable Transitions, Crash-Durability-Review (Source-Dir-fsync fehlt noch, .tmp-Cleanup, fsync-unsupported) + ggf. scoped Fix.)
