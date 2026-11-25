Title: "starfleetctl Plugin-Integrationstests gegen Comms-/Session-Handoff-Regressionen"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Discovery"
Created-By: "Discovery"
Created: "2026-11-25T15:17:37Z"
Doc-Ref: "—"

- 2026-11-25T15:17:56Z Discovery: began work

- 2026-11-25T15:25:36Z Discovery: progress 50% (Created integration test file fragments/opencode-plugins/starfleet-dispatch.integration.test.ts with 15 tests covering all 5 regression areas: (a) Session-Recovery with realistic OpenCode session shapes (modern time.updated, legacy updated, missing/invalid timestamps, workspace/ship mapping); (b) session.list errors, empty/unexpected SDK wrapper, missing session context; (c) Comms bus/inbox errors (CLI exit!=0, malformed JSON, {ok:false}, Timeout); (d) promptAsync errors/exceptions and seen_mark/ACK errors; (e) Poller/system.transform races, parallel polls, boot backlog, restart/process abort. All tests pass (15/15). Original 53 pure logic tests still pass. Plugin build checks (esbuild + tsc) clean.)
