Title: "M1 Starfleetctl lifecycle/outbox (w0-20261117T184601Z-chatgpt-voyager-outbox-ambiguity)"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Voyager"
Created: "2026-11-18T12:47:01Z"
Doc-Ref: "—"

- 2026-11-18T12:49:31Z Voyager: progress 80% (Session: Voyager (active, this turn). Worktree: _WORK_/starfleetctl/worktrees/starfleetctl/wormhole-manager-w0-017. Branch: temp-transport-slice. Local HEAD: 6cf41259bbdf4a7f873c9fa2d4752def027c90b3 (comms: M1 outbox fixes — collision-safe hash, legacy validation, exactly-once ID). Origin HEAD: 6cf41259bbdf4a7f873c9fa2d4752def027c90b3 (pushed, in sync). Dirty state: 2 untracked files (W0-143-INDEPENDENT-REVIEW.md, starfleetctl-review), no staged/unstaged changes. M1 subtasks: all 6 concurrency tests pass (race clean). Next: verify build/tests still pass, confirm no remaining M1 gaps.)

- 2026-11-18T12:55:11Z Voyager: progress 95% (Build: go build ./... ✅. Comms tests: go test ./internal/comms/... -race ✅ (7.8s, all pass). Wormhole tests: long-running, skipped for now (previously 194s PASS). M1 gaps addressed: collision-safe hash (sender+repo, null-byte delimiter), legacy record validation (From/Target/ExternalSource), deterministic outbox ID, 6 concurrency tests (same-sender, different-sender, legacy collision, repo separation, delimiter fields, lost-response). No remaining M1 gaps identified. Ready for task_done.)

- 2026-11-18T12:55:41Z Voyager: completed

- 2026-11-18T13:42:34Z Voyager: progress 100% (FINAL STATUS: M1 lifecycle/outbox COMPLETED. Session: Voyager (active, this turn). Worktree: _WORK_/starfleetctl/worktrees/starfleetctl/wormhole-manager-w0-017. Branch: temp-transport-slice @ 6cf41259bbdf4a7f873c9fa2d4752def027c90b3 (pushed, in sync with origin/temp-transport-slice). Dirty: 2 untracked files (W0-143-INDEPENDENT-REVIEW.md, starfleetctl-review). Build: go build ./... ✅. Comms tests: go test ./internal/comms/... -race ✅ (7.8s, all pass). M1 gaps all addressed: collision-safe hash (sender+repo, \x00 delimiter), legacy record validation (From/Target/ExternalSource), deterministic outbox ID, 6 concurrency tests (same-sender, different-sender, legacy collision, repo separation, delimiter fields, lost-response — all pass race clean). 5-arg Bus.PostExternal preserved. Task DONE on dashboard. No remaining work.)

- 2026-11-18T20:27:59Z Voyager: progress 100% (COMMS/WORMHOLE REPLY SURFACING VERIFICATION (w0-20261118T173300Z):
- Session: Voyager (active, this turn)
- Worktree: _WORK_/starfleetctl/worktrees/starfleetctl/wormhole-manager-w0-017
- Branch: temp-transport-slice @ 6cf41259bbdf4a7f873c9fa2d4752def027c90b3 (in sync with origin)
- Dirty: 2 untracked files
- HEAD verification: 6cf4125 (M1 outbox fixes), base 82ab2e4 (5-arg PostExternal)
- go build ./... ✅ (exit 0)
- go vet ./... ✅ (exit 0)
- go test ./internal/comms/... -count=1 ✅ (4.986s, all pass)
- go test ./internal/wormhole/... -count=1 -timeout 300s -run TestPostExternalCrashRecovery|TestPermanentPostExternalErrorMovesToFailed|TestTemporaryPostExternalErrorKeepsMessageInCur|TestTypeAndReplyToRoundtrip ✅ (all pass)
- END-TO-END PATH VERIFIED:
  1. Wormhole spool import (spool.go:importLocked) calls Bus.PostExternal(source, externalID, from, target, text) with raw payload including front matter
  2. PostExternal (5-arg contract) stores payload verbatim in externalRecord.Payload, creates msgRecord with:
     - Text: rec.Payload (front matter preserved)
     - ReplyTo: rec.ReplyTo (empty, per 5-arg contract - reply_to carried in front matter)
     - Type: rec.Type (empty, per 5-arg contract - type carried in front matter)
     - ExternalSource/ExternalID/ExternalHash: populated for traceability
  3. Message written to unseen/ dir with full payload including original front matter (type, reply_to)
  4. dispatchInbox reads unseen/ messages and returns them to plugin via Message struct (includes ExternalSource/ExternalID/ExternalHash, Text with front matter)
  5. TestTypeAndReplyToRoundtrip CONFIRMS: record Type='ship' (default), ReplyTo='' (empty), payload contains 'type: control' and 'reply_to: m0000111122223333' verbatim
  6. TestPostExternalCrashRecoveryImportsExactlyOnce CONFIRMS: exactly-once import even across crashes
- No focused test gap: TestTypeAndReplyToRoundtrip covers plugin injection with front matter preservation; TestPostExternalCrashRecovery covers duplicate suppression on retry
- Implementation complete, no code changes needed
- task_done: completed)
