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

- 2026-11-25T15:28:53Z Discovery: progress 100% (Plugin integration tests complete. Commit a252e6a pushed to work/wormhole-manager-w0-017.

SUMMARY:
✅ 15 integration tests added in fragments/opencode-plugins/starfleet-dispatch.integration.test.ts
✅ All 5 regression areas covered:
   a) Session-Recovery: modern time.updated, legacy updated, missing/invalid timestamps, workspace/ship mapping
   b) session.list errors: CLI exit!=0, empty/unexpected SDK wrapper, missing session context
   c) Comms bus/inbox errors: CLI exit!=0, malformed JSON, {ok:false}, Timeout/Exception
   d) promptAsync/seen_mark errors: error objects, exceptions, string errors, ACK failures
   e) Race conditions: poll/transform races, parallel polls, boot backlog, restart recovery

✅ 53 original pure logic tests still pass
✅ Plugin build checks pass (esbuild bundle + tsc --noEmit on project)
✅ All Go internal tests pass
✅ Production gaps documented: seen_mark failure after submitted.add loses message; command handling lacks submitted check

Tests are deterministic: no real network, ships, Comms data, or restarts. Use fake timers and controllable promises. Test names follow queued/accepted/injected/seen convention (no 'model completed' claims).)
