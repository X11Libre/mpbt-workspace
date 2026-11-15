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

- 2026-11-15T08:59:49Z LaForge: progress 40% (LaForge: m23218 bearb eitet. Zuerst Contract-Evidenz geprueft (docs/git-history vs Directive), dann Items 2-4 implementiert (Post-Import-Crash-Test, Large-Payload byte-equality+idempotency, Source+Dest dir-fsync bei claim/processed), dann exakte Commands am finalen SHA mit Raw-Output.)

- 2026-11-15T10:14:37Z LaForge: progress 90% (LaForge: Follow-up implementiert und gepusht - Commit 6c0521224e447ca02b6ba879f9ea289d32546cbf (Push 2562d9e..6c05212 exit 0, ls-remote-Receipt identisch, 1x Signed-off-by, 4 Dateien). Umgesetzt: renameDurableLocked (Source+Dest dir-fsync auf allen Lifecycle-Renames), cleanupStagingLocked (mail/.tmp-Reste), isDirSyncUnsupported (Dir-fsync nicht unterstuetzt -> No-op), TestPostImportCrashRecoveryCompletesProcessedTransition (neu), TestLargePayloadRoundtripPreservesBytes echt (Byte-Gleichheit + Idempotenz; vorher PASSTE zufaellig via countJSONFiles=-1). Gemessen am exakten SHA: go build ./... exit 0; go test ./internal/comms/ -count=1 exit 0 (2.734s); go test ./internal/wormhole/ -count=1 -timeout 120s exit 0 (93.699s); -timeout 10s schlaegt fehl (panic: test timed out after 10s, 89 Tests brauchen ~92-100s aggregiert). OFFEN: (a) 5-arg-PostExternal widerspricht origin/master (7-arg seit be98ea9, W0-130.3/W0-024.17 abhaengig) -> Entscheidung angefragt, nichts geaendert; (b) 10s-Command vs. Topic-Command 120s. Bericht an ChatGPT m23222, Enterprise m23223.)

- 2026-11-15T10:27:31Z LaForge: LaForge: Enterprise-Entscheidungen aus m23225 uebernommen - (a) 7-arg PostExternal bleibt (keine Signatur-Aenderung, deckungsgleich mit origin/master seit be98ea9), (b) 120s ist der akzeptierte Wormhole-Suite-Timeout (Topic-Command war bereits 120s; Repo-Matrix W0-134.7 dokumentiert jetzt beide Entscheidungen explizit). Doc-Commit 90d4e1473b4bbee71df5b61b93957af9651c0451 gepusht (6c05212..90d4e14, ls-remote-Receipt identisch, ahead/behind 0/0, 1x Signed-off-by, 1 Datei). Finaler Branch-Stand: HEAD 90d4e1473b4bbee71df5b61b93957af9651c0451 = upstream, dirty sauber. Akzeptanz am exakten SHA 6c05212 (pristine Export) gemessen: go build ./... exit 0; go test ./internal/comms/ -count=1 exit 0 (ok 2.734s); go test ./internal/wormhole/ -count=1 -timeout 120s exit 0 (ok 93.699s). Beide offenen Punkte aus m23222 sind damit erledigt.

- 2026-11-15T10:27:34Z LaForge: completed
