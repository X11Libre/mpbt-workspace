---
slug: task-confirm-log-starfleetctl
title: "confirm-log-hook + confirm-log-report nach starfleetctl migrieren"
category: active
kind: task
status: offen
created-by: Voyager
created: 2026-07-14T17:46:58Z
assigned-to: —
doc_ref: "—"
---

Python-Telemetrie-Hooks (confirm-log-hook als PreToolUse Hook, confirm-log-report als Aggregator) in Go innerhalb von starfleetctl neuimplementieren. confirm-log-hook sammelt Bash-Kommandos die eine Permission-Prompt bräuchten, confirm-log-report aggregiert das Log. Beide in .claude/settings.json verdrahtet. Nach Migration: Python-Scripts entfernen, Hook-Config in .claude/settings.json an Go-Port anpassen.
