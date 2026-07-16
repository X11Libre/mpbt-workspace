---
slug: task-web-frontend-ship-control
title: "Background-Schiffe via Web Frontend starten / stoppen / Status prüfen"
category: active
kind: task
status: open
created-by: Yamato
created: 2026-07-16T18:24:39Z
assigned-to: —
doc_ref: "—"
---

Implementiere ein Web Frontend um Background-Schiffe (Fleet Ships) zu verwalten:
- Schiffe starten (commission)
- Schiffe stoppen (decommission/idle)
- Status prüfen (idle/working/stale/offline)
- Über agent-bus Kommunikation steuern

Akzeptanzkriterien:
- Web UI zeigt alle Schiffe mit Status an
- Buttons für Start/Stop/Restart
- Live-Status-Updates via agent-bus Polling
- Integration in bestehendes Dashboard
