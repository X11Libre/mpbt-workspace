Title: "Read-only Comms event pipeline architecture review"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Discovery"
Created-By: "Discovery"
Created: "2026-11-25T17:31:48Z"
Doc-Ref: "—"

- 2026-11-25T17:32:05Z Discovery: began work

- 2026-11-25T17:36:29Z Discovery: progress 100% (Read-only Comms event pipeline architecture review complete.

CURRENT STATE:
- Worktree: /home/nekrad/src/xorg/mpbt-workspace/_WORK_/starfleetctl/sources/starfleetctl
- Branch: work/wormhole-manager-w0-017 (HEAD a252e6a)
- Task: task-read-only-comms-event-pipeline-architecture-review (in_progress)
- Reviewing: feat/comms-event-pipeline branch (origin/feat/comms-event-pipeline, HEAD eb509a8)
- Deployed OpenCode CLI/SDK: 1.19.3 (per Enterprise coordination)

## FINDINGS

### 1. Architecture Boundary Compliance (doc/comms-event-pipeline.md Section "Responsibility boundary")
**Severity: MAJOR - Violation in current master plugin**

- **Design rule**: "Go owns message-to-prompt composition... Go does not know about OpenCode SDK types, hook names, output.system, promptAsync, or the position where text is inserted."
- **Current master (2.5.14) VIOLATION**: The plugin composes the full prompt text INCLUDING Comms formatting ("--- fleet directives ---", "Directive m123 from Enterprise:", "--- end fleet directives ---") inside the `system.transform` hook. The Go layer only returns raw inbox messages.
- **feat/comms-event-pipeline FIX**: Introduces `preparePrompt`/`prepareLegacyInboxPrompt` in `prompt-preparation.ts` as the SINGLE shared formatter. Both `system.transform` and future event-based adapters consume the SAME `PreparedPrompt`. Go will eventually return pre-formatted prompt via event contract.
- **Gap**: The design document says "The event payload carries that text as a string or string array" — but the current Go `inbox` command returns raw messages, not formatted prompt. Migration plan step 4 needed.

### 2. OpenCode Version/API Compatibility (doc/comms-event-pipeline.md "OpenCode compatibility prerequisite")
**Severity: MAJOR - Unverified assumptions**

- **Design requirement**: "Before implementing or freezing adapter signatures, capture the exact deployed OpenCode CLI/runtime version and the corresponding plugin SDK/API... Record the observed version, hook signatures, and observable turn-start/completion events."
- **Current state**: Deployed OpenCode = 1.19.3 (CLI) / @opencode-ai/plugin SDK = 1.19.3. The feat/comms-event-pipeline plugin uses:
  - `client.session.promptAsync` (V1 API) — works with 1.19.3
  - `output.system` in `system.transform` hook (V1) — works
  - `event.type === 'session.created'` etc. (V1 event hooks)
- **Risk**: The design doc mentions V2 plugin API with `ctx.tool.hook("execute.before")` and `ctx.permission.assert`. The current plugin does NOT use V2 hooks. If OpenCode 1.19.3 supports V2, the plugin should be validated against V2 signatures. If it only supports V1, the V2 references in the design doc are forward-looking.
- **Missing**: No compatibility note documenting the exact hook signatures observed in 1.19.3.

### 3. Lifecycle/Ack Ambiguity (doc/comms-event-pipeline.md "Lifecycle and acknowledgement semantics")
**Severity: MAJOR - Overloaded seen_mark**

- **Design requirement**: "Do not overload the existing seen_mark operation. At minimum, distinguish: offered, applied/submitted, turn_started, completed, failed."
- **Current feat/comms-event-pipeline**: Still uses `seen_mark` for both "offered" (message returned by poll) AND "submitted" (injected via system.transform) AND "command executed". The plugin's `submitted` Set tracks deduplication but `seen_mark` is called for ALL cases.
- **Gap**: No distinct lifecycle reporting in Comms. The `seen_mark` call cannot distinguish between:
  - Message polled but not yet injected (offered)
  - Message injected into current turn (submitted/applied)
  - Command executed (accepted)
  - Turn actually started (turn_started)
  - Turn completed (completed)
- **Impact**: Cannot implement retryable/permanent classification per the design. Duplicate detection via `submitted` Set is in-memory only — not durable across restarts.

### 4. Ordering/Idempotency/Retry Issues
**Severity: MAJOR - In-memory deduplication only**

- **Design requirement**: "A single event dispatcher owns polling, validation, ordering, deduplication, and the pending queue... The durable event state and lease/retry policy belong in Comms. Plugin-local state may prevent duplicate concurrent work but cannot be the source of truth."
- **Current feat/comms-event-pipeline**: 
  - `submitted` Set is in-memory only (lost on plugin restart)
  - `pollRunning` guard prevents concurrent polls but not concurrent `system.transform` + `poll`
  - `bootBacklog` is reconstructed from inbox on each poll — but no durable record of what was already processed
  - No lease mechanism in Comms for message delivery
- **Gap**: After plugin restart, messages in inbox will be re-processed. The `seen_mark` on Comms side provides some idempotency, but the plugin has no durable record of what it already injected.

### 5. V1 Runtime Compatibility Assumptions
**Severity: MINOR - Mixed V1/V2 references**

- **Design doc mentions**: V2 plugin API (`ctx.tool.hook`, `ctx.permission.assert`, PR #54930)
- **Current plugin**: Uses V1 hooks (`system.transform`, `chat.params`, `event` with `session.created`, `session.error`, `message.updated`)
- **Issue**: The design doc's "OpenCode compatibility prerequisite" section references V2 API research but the implementation uses V1. No clear statement of which API version is the target.
- **Recommendation**: Document "Target: OpenCode 1.19.3 V1 plugin API" or migrate to V2 if that's the intent.

### 6. Missing Tests (doc/comms-event-pipeline.md "Required tests")
**Severity: MAJOR - Most required tests not implemented**

| Required Test | Status |
|---------------|--------|
| Formatter output identical regardless of delivery adapter | ✅ `preparePrompt`/`prepareLegacyInboxPrompt` tests added (eb509a8) |
| Multiple messages preserve order and grouping | ❌ Not tested |
| Single event not submitted by both adapters or twice concurrently | ❌ Not tested (no dual-adapter implementation yet) |
| Poll failure, malformed response, unknown event, adapter failure observable | ⚠️ `normalizeInboxResponse` handles malformed response; others not tested |
| Retry after failure and recovery after plugin restart idempotent | ❌ Not tested (no restart recovery test) |
| Current-turn and new-turn adapters preserve existing behavior | ❌ Only current-turn (`system.transform`) implemented; new-turn (`promptAsync`) adapter not yet extracted |
| Lifecycle tests prove offered/submitted/turn_started/completed distinct | ❌ Only `seen_mark` used |
| E2E: Comms message -> poll -> prepared prompt -> adapter -> observed turn start -> completion ack | ❌ Not tested |

### 7. Cross-Branch Consistency
**Severity: NOTE**

- **work/wormhole-manager-w0-017** (current): Plugin v2.5.14, uses legacy inbox polling, has integration tests for handoff regressions
- **feat/comms-event-pipeline**: Plugin v2.5.18, introduces event-based architecture, new modules (`prompt-preparation.ts`, `session-resolution.mjs`, `inbox-response.mjs`, `runtime-identity.mjs`), shared `PreparedPrompt` type
- **Divergence**: The two branches have different plugin architectures. The wormhole-manager branch has integration tests for regressions; the event-pipeline branch has unit tests for the new shared formatter. They should be merged or one should supersede the other.

### 8. GitHub Issue #23 Alignment
**Severity: NOTE**

- Issue #23: "Comms event delivery pipeline" — design baseline captured in `doc/comms-event-pipeline.md`
- The feat/comms-event-pipeline branch implements the design incrementally
- Current implementation status: Steps 1-2 partially complete (compatibility baseline, shared prompt preparation). Steps 3-6 not yet implemented.

## RECOMMENDED MINIMAL CORRECTIONS

1. **Add OpenCode compatibility note** to `doc/comms-event-pipeline.md` documenting exact 1.19.3 V1 hook signatures observed.

2. **Implement distinct lifecycle reporting** in Comms: add `event_delivery` command with states `offered|submitted|turn_started|completed|failed` instead of overloading `seen_mark`.

3. **Add durable lease/idempotency in Comms** for message delivery (plugin-local `submitted` Set is insufficient for restart recovery).

4. **Complete adapter extraction**: Separate `promptAsync` new-turn adapter from `system.transform` current-turn adapter, both consuming `PreparedPrompt`.

5. **Implement missing required tests** from design doc (ordering, dual-adapter exclusion, retry/restart idempotency, lifecycle distinctions, E2E).

6. **Merge decision**: Either merge feat/comms-event-pipeline into work/wormhole-manager-w0-017 (or master), or declare one as the active line. Current divergence creates maintenance burden.

7. **Plugin version sync**: feat/comms-event-pipeline is at 2.5.18; current deployed is 2.5.17 (per Enterprise coordination). Ensure version bump reflects actual changes.)
