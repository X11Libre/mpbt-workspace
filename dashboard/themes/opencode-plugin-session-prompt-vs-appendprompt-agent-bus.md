---
slug: opencode-plugin-session-prompt-vs-appendprompt-agent-bus
title: "opencode plugin: session.prompt() vs tui.appendPrompt() for agent-bus"
category: active
status: "Entwurf / in Diskussion"
doc_ref: "—"
---

# opencode plugin: session.prompt() vs tui.appendPrompt() for agent-bus messages

## Problem
The current `agent-bus-poller.ts` uses:
```typescript
await client.tui.appendPrompt({ body: { text: `\n📨 ${text}` } })
await client.tui.submitPrompt()
```
This puts the message **in the input field** briefly before submitting — visible to user, clutters input.

## Better approach: `client.session.prompt()` or `client.session.promptAsync()`

### SDK methods available:
- `client.session.prompt({ path: { id: sessionId }, body: { parts: [...] } })` — adds to conversation history, triggers agent turn, waits for reply
- `client.session.promptAsync({ path: { id: sessionId }, body: { parts: [...] } })` — fire-and-forget, adds to history, triggers turn, returns immediately

### Parts format:
```typescript
parts: [{ type: "text", text: `📨 [${msg.id}] from ${msg.from}: ${msg.text}` }]
```

### What you need:
- **Session ID** — available from:
  - `session.created` event (in `event` hook)
  - `session.list()` via `client.session.list()`
  - `experimental.chat.system.transform` hook input has `sessionID`

### Comparison:

| Method | In chat history | In input field | Triggers turn | Waits for reply |
|--------|----------------|----------------|---------------|-----------------|
| `tui.appendPrompt` + `submitPrompt` | After submit | Yes (briefly) | Yes | Yes |
| `session.prompt()` | Immediately | **No** | Yes | Yes |
| `session.promptAsync()` | Immediately | **No** | Yes | No (fire-and-forget) |

## Implementation plan for agent-bus-poller.ts

1. Track current `sessionId` in plugin state (set on `session.created`, `session.cleared`, `session.reset`)
2. Replace `submit()` function with:
```typescript
const submit = async (text: string) => {
  if (!tuiReady || !sessionId) return false
  try {
    await client.session.promptAsync({
      path: { id: sessionId },
      body: { parts: [{ type: "text", text }] }
    })
    return true
  } catch { return false }
}
```
3. Remove `tuiReady` dependency (session API works without TUI ready)

## Benefits
- Messages appear in chat history immediately (visible to user)
- No flicker in input field
- Cleaner UX — messages are "incoming" not "typed"
- `promptAsync` avoids blocking the poll loop

## Files to modify
- `.opencode/plugins/agent-bus-poller.ts` (canonical in `starfleetctl` repo fragments)