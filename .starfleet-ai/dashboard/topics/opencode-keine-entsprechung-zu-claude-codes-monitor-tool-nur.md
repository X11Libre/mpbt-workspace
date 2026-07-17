---
slug: opencode-keine-entsprechung-zu-claude-codes-monitor-tool-nur
title: "opencode: keine Entsprechung zu Claude Codes `Monitor`-Tool → nur Notify, kein In-Context-Auto-Surfacing von agent-bus-Direktiven"
category: parked
noted_by: "praetor, 2026-07-03"
since: "2026-07-03"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Seit heute nutzen Claude-Code-Sessions einen `Monitor`-Watch auf die eigene agent-bus-Inbox, damit `tell`/`broadcast` direkt im Gespräch als Event auftaucht statt nur als Desktop-Notification (siehe `AGENTS.md`, agent-bus-Abschnitt „Auto-surfacing directives via Monitor"). opencode-Sessions (`run-opencode.xserver-*`) haben kein äquivalentes In-Context-Event-Mechanismus und bleiben auf reines Notify angewiesen (aktuell nicht mal das — `agent-bus-watch` ist nur per Claude-Code-Hook verdrahtet). Aufgabe: opencode so anpassen, dass zumindest Desktop-Notifications (`agent-bus-watch`) auch dort laufen — z.B. `run-opencode.*` startet `scripts/agent-bus-watch` selbst detached, analog zum Claude-Code-`SessionStart`-Hook. Volles In-Context-Surfacing bräuchte ein opencode-seitiges Äquivalent zu `Monitor`, falls es sowas gibt — noch nicht recherchiert. Nichts gestartet.
