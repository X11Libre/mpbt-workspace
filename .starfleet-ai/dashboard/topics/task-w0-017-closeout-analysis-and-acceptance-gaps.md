Title: "W0-017 closeout analysis and acceptance gaps"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Discovery"
Created-By: "Discovery"
Created: "2026-11-24T19:32:03Z"
Doc-Ref: "—"

- 2026-11-24T19:32:32Z Discovery: began work

- 2026-11-25T10:09:05Z Discovery: progress 30% (Analyzed current work branch state. work/wormhole-manager-w0-017 is at 245e40a (includes fix for STARFLEET_* env filtering). Origin branch is at e2b2a2e. All internal tests pass. Need to identify acceptance gaps vs W0-017 requirements.)

- 2026-11-25T10:13:17Z Discovery: progress 70% (Analyzed W0-017 requirement matrix (doc/wormhole-requirement-matrix.md). 94 requirement rows: 87 IMPLEMENTED+TESTED, 3 PARTIALLY TESTED (GT-1,2,5), 2 Unix-only (GT-3,6), 2 MANUALLY REVIEWED (docs). Key acceptance gaps: (1) W0-134.7 owner-required 10s wormhole test timeout FAILS structurally (~84-130s for 89 sequential git tests) — blocked on Owner relaxation. (2) Task w0-20261114T124100Z (chat history integration) has outbox recording tests (TestPostExternalOutboxRecord, TestPostExternalReplyCorrelation) but no chat-history display test. (3) metux/wormhole-0 transport evidence minimal (only outbox dir). All internal tests pass; go build/go vet clean.)
