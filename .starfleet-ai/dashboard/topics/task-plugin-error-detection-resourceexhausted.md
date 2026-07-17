---
slug: task-plugin-error-detection-resourceexhausted
title: "Plugin Error Detection: ResourceExhausted & Rate-Limit Errors"
category: active
kind: task
status: open
created-by: Yamato
created: 2026-07-17T06:40:38Z
assigned-to: —
doc_ref: "—"
---

Plugin-System soll Model/API-Fehler erkennen und im Web-Frontend anzeigen mit Restart-Option.

Spezifische Fehler:
- 'ResourceExhausted: Worker local total request limit reached'
- NIM overload errors
- ZEN rate-limit blocks
- Generic 429/503 errors

Funktionalität:
- Fehler-Erkennung im Plugin/Proxy Layer
- Web-Frontend: Fehler-Liste mit Timestamp, Agent, Error-Type, Details
- Manuelle Restart-Option: 'Continue' Button sendet 'continue' an Agent via agent-bus
- Automatische Restart-Option: Konfigurierbare Retry-Logik (exponential backoff, max retries)
- Error-Context speichern (Request, Response, Stacktrace)
- Dashboard-Integration: Error-Panel mit Filtern (Agent, Error-Type, Zeit)

Akzeptanzkriterien:
- ResourceExhausted Fehler werden erkannt und geloggt
- Web UI zeigt Fehler mit 'Continue' Button
- Klick auf 'Continue' sendet agent-bus tell <agent> 'continue'
- Auto-Retry konfigurierbar (on/off, max-retries, backoff)
- Fehler-History im Dashboard abrufbar
