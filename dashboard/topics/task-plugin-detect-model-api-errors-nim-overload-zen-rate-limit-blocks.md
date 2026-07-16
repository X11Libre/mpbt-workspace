---
slug: task-plugin-detect-model-api-errors-nim-overload-zen-rate-limit-blocks
title: "Plugin: detect model API errors (NIM overload, ZEN rate-limit blocks)"
category: active
kind: task
status: open
created-by: Defiant
created: 2026-07-16T17:01:23Z
assigned-to: —
doc_ref: "—"
---

The starfleet-dispatch opencode plugin should detect when the model API fails and react appropriately. Two known failure modes: (1) NIM (NVIDIA inference microservices) occasionally aborts due to overload — returns 5xx or connection errors. (2) ZEN temporarily blocks accounts for several hours when usage is too high — returns 429 or access-denied. The plugin should detect these error patterns, log them to the agent-bus event log, update the ship health state (e.g. 'blocked' or 'rate-limited'), and optionally notify the flagship. This helps the fleet understand why a ship stopped responding without manual investigation. Acceptance: error detection works for both NIM and ZEN patterns, health state reflects the error, and the ship recovers automatically when the API becomes available again.
