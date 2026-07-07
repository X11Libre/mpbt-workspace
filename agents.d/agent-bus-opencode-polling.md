---
slug: agent-bus-opencode-polling
title: "Agent-bus opencode polling"
order: 215
---

## Agent-bus opencode polling

opencode has no `Monitor` tool (Claude Code only), so the background
`agent-bus-monitor-loop` cannot surface directives as in-context events.
Instead, the `.opencode/plugins/agent-bus-poller.ts` plugin injects new
tell/broadcast directives into the system prompt at the start of each
turn via the `experimental.chat.system.transform` hook. No manual check
command is needed — new messages appear automatically in context.

If new directives are shown, the assistant should handle them as it would
if they had surfaced via a Monitor event — ack, act, or defer as
appropriate. The plugin shares dedup state with `agent-bus-monitor-loop`
so the same message is only shown once regardless of which mechanism
surfaced it first.
