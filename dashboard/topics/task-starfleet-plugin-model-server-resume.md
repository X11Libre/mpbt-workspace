---
slug: task-starfleet-plugin-model-server-resume
title: "starfleet Plugin: Model/Server Registrierung + Web Resume für Error-Agents"
category: active
kind: task
status: open
created-by: Yamato
created: 2026-07-16T19:05:26Z
assigned-to: —
doc_ref: "—"
---

Plugin-System für starfleet: Models/Servers registrieren, im Web sichtbar machen, und Error-Agents per Web UI fortsetzen.

Funktionalität:
- Plugin-API: Models/Servers registrieren (name, version, capabilities, health-endpoint)
- Web Frontend: Registrierte Models/Servers anzeigen (Dashboard)
- Error-Handling: Agents die mit Error gestoppt wurden, im Web UI sichtbar machen
- Resume-Funktion: Per Web UI Agent neu starten / fortsetzen (mit Error-Context)
- Agent-Bus Integration: Error-Events an Prometheus/Enterprise senden

Akzeptanzkriterien:
- Plugin registriert Model/Server über API
- Web UI zeigt alle registrierten Models/Servers mit Status
- Error-Agents werden im Web UI gelistet (mit Error-Details, Stacktrace)
- 'Resume' Button startet Agent neu mit Error-Context
- Error-Events gehen über agent-bus an Prometheus
- Integration in bestehendes starfleetctl / Dashboard
