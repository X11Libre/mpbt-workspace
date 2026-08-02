Title: "starfleet-dispatch Plugin v2.4.1: Critical Fixes & Lessons Learned"
Category: active
Kind: task
Status: open
Created-By: Phoenix
Created: 2026-07-30T14:14:41Z
Assigned-To: —
Doc-Ref: "—"
Slug: plugin-v2.4.1-fixes-lessons-learned

# starfleet-dispatch Plugin v2.4.1: Critical Fixes & Lessons Learned

## Summary

Fixed critical crashes in starfleet-dispatch opencode plugin (v2.4.0 → v2.4.1) that prevented model-switch commands and comms processing.

### Root Cause (3 bugs)
1. **ReferenceError: client is not defined** — `toast()` function defined at module level but referenced `client` from plugin closure
2. **TypeError: bus(...).catch is not a function** — `bus()` uses `execSync` (synchronous), returns parsed JSON directly, not a Promise
3. **Commands never processed** — `poll()` had `if (!currentSessionID) return` guard; if `session.created` event was missed (race), `currentSessionID` stayed empty forever → inbox never polled

### Fixes Applied
- Moved `toast()` / `toastBus()` factories inside plugin closure where `client`/`bus` are in scope
- Removed `.catch()` from `bus()` calls (synchronous)
- Removed `!currentSessionID` guard from `poll()` — now calls `resolveSessionId()` which reads `client.session.status()` lazily
- Added `resolveSid()` / `doSwitchModel()` helpers that resolve session ID at call time
- All command handlers (`model`, `setModel`, `abort-retry`, `reset`, `quit`, `status`) now use async session resolution

### New Features
- **Plugin version tracking**: `PLUGIN_VERSION = '2.4.1'` in heartbeat + status (visible in dashboard)
- **Toast/bus comms**: `dispatchToast` in Go logs toasts + emits `ToastVariant/Title/Message` in status for web UI
- **Web UI model-switch**: Dropdown always visible (removed `if(s.model)` guard), placeholder + pre-select current model

### Comms Loop Verification
All 6 directions working:
- Phoenix → Enterprise (model, status, directives)
- Enterprise → Phoenix (replies, model-switch)
- Phoenix → Lexington
- Lexington → Phoenix
- Enterprise → Lexington
- Lexington → Enterprise

### Files Changed (8)
- fragments/opencode-plugins/starfleet-dispatch.ts (major rewrite)
- internal/comms/dispatch.go (dispatchToast, toast fields)
- internal/comms/records.go (ToastVariant/Title/Message in StatusRecord/Patch)
- internal/comms/commands.go (DoStatus merges toast fields)
- internal/comms/dispatch_test.go (temp dir with fallback_model for test)
- internal/session/launch.go (plugin path fix)
- internal/session/run_cmd.go (plugin path fix)
- internal/web/index.html (model dropdown always visible)

## Lessons Learned for Future Plugin Work

### 1. Plugin scope matters
opencode loads plugins as `module.exports = async ({ client, events, opts }) => { ... }`
Any function needing `client`/`events`/bus MUST be defined INSIDE that async function.
Module-level functions only see module-level scope — no access to `client`!

### 2. Synchronous vs async boundaries
- `execSync` returns result directly, not Promise
- Never call `.then()`/.catch() on `bus()` return value
- If you need async bus, wrap in `Promise.resolve()` or use separate async wrapper

### 3. Session lifecycle race conditions
- `session.created` event fires ONCE — if plugin loads after, event is missed
- Always have fallback: `client.session.status()` to discover existing sessions
- Don't gate critical paths (poll, commands) on event-derived state

### 4. Defensive session ID resolution
- `resolveSessionId()` pattern: check cache → check closure var → call `client.session.status()` → pick first key
- Call it at point of use (commands) not just at init
- Update `currentModel` from status when resolving (model may be set before plugin loads)

### 5. Plugin path in OPENCODE_CONFIG_CONTENT
- Path is relative to CWD where opencode runs (workspace root)
- Must be `./.opencode/plugins/starfleet-dispatch.ts` NOT `./plugins/...`
- Fixed in both `run_cmd.go` and `launch.go`

### 6. WebSocket/TUI availability
- `client.tui` only exists in terminal mode, not in detached/auto mode
- Always wrap `client.tui.showToast()` in try/catch
- Provide bus fallback (`toastBus`) so web UI gets notifications even without TUI

### 7. Testing patterns
- `decideAction` needs real config: create temp dir with `.starfleet-ai/conf/comms.yaml` containing `fallback_model`
- Use `t.TempDir()` for isolation

### 8. Status schema evolution
- When adding fields (ToastVariant/Title/Message), update BOTH StatusRecord AND StatusPatch
- Update DoStatus merge logic in commands.go
- Web UI reads these from status JSON automatically

### 9. Plugin versioning
- Hardcode `const PLUGIN_VERSION = 'x.y.z'` at top of fragment
- Include in init heartbeat + periodic heartbeat + session.created health update
- Dashboard shows it automatically via board status

### 10. Model-switch command flow
- Web UI sends `/api/cmd` → `s.bus.Command()` → `b.post(..., type="command")`
- Plugin poll reads inbox → `handleMessage(type="command", verb="model")`
- Uses `resolveSid()` → `doSwitchModel(sid, targetModel, src)`
- On success: updates `currentModel`, sends health + toastBus

### 11. Web UI model dropdown
- Always render dropdown (remove `if(s.model)` guard)
- Populate from `ns_model` options (single source of truth)
- Add placeholder option, pre-select current model if known
- On click: POST `/api/cmd` with `{target, verb: 'model', args: model}`
