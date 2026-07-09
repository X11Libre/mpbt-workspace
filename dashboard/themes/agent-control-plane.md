---
slug: agent-control-plane
title: "Agent control plane (\"1st officer\" — one central contact for many workers)"
category: active
status: "Steps 1 **and** 2 **done** (ask/reply + notify watcher + permission-forward hook); tested"
doc_ref: "`AGENT-CONTROL-PLANE.md`; `scripts/agent-bus` (`ask`/`reply`/`asks`), `scripts/starfleetctl hook claude permission`, `scripts/agent-bus-watch`, `scripts/agent-permission-hook`"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Worker `agent-bus ask "<q>"` blocks on a local file-poll (no API) for the controller's reply; controller uses `agent-bus asks` / `reply <qid>`. Notify watcher auto-starts per session (SessionStart hook). Tool approvals route to the controller via the opt-in `PreToolUse` hook `agent-permission-hook` (per-worker `settings.local.json`; fail-closed deny on no answer). **Longer term:** MCP push-bus instead of file polling
