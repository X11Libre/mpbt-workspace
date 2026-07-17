---
slug: starfleet-telegram-integration-send-receive-telegram-message
title: "Starfleet ↔ Telegram integration — send & receive Telegram messages"
category: active
status: "Idea stage — just requested, nothing started"
doc_ref: "no doc/branch yet"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Praetor request, 2026-07-03. Goal: bridge the fleet control plane (`agent-bus`/`starfleetctl`) with Telegram so directives/notifications can be sent and received via a Telegram bot, not just desktop notify (`agent-bus-watch`) or in-context `Monitor` surfacing (see "Agent control plane" row). Scope/design not yet discussed with praetor — bot token handling, which side initiates (agent-bus → Telegram push, and/or Telegram → agent-bus `tell`), self-hosted-only per [[prefers-self-hosted-no-cloud]] preference (a Telegram bot itself is a cloud API dependency, so this should be flagged/confirmed with the praetor before building, not assumed in conflict with that preference).
