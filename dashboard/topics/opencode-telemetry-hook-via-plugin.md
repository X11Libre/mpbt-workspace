---
slug: opencode-telemetry-hook-via-plugin
title: "opencode: Telemetry-Hook via Plugin"
category: active
status: open
since: 2026-07-15
---

# opencode: Telemetry-Hook via Plugin

## Status
open

## Context
`starfleetctl hook opencode telemetry` ist ein PreToolUse-Telemetry-Hook
(tool-usage-logging für Fleet-Monitoring). Opencode unterstützt kein
`hooks`-Schema im Config (nur Claude Code via `.claude/settings.json`).

## Task
Einen opencode-Plugin schreiben, der vor jedem Bash-Tool-Aufruf
`starfleetctl hook opencode telemetry` triggert — oder alternativ
die Telemetry-Logik direkt in den bestehenden `starfleet-dispatch.ts`
Plugin integrieren.

## Ansatz
- opencode Plugins haben Zugriff auf Tool-Events
- Prüfen ob opencode PreToolUse-Hooks über Plugins möglich sind
- Falls nicht: Periodischer Telemetry-Push (Heartbeat) als Alternative
