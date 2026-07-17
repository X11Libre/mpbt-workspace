---
slug: task-starfleet-timer-function
title: "starfleet: Timer-Funktion für Schiffe"
category: active
kind: task
status: open
created-by: Yamato
created: 2026-07-16T19:03:19Z
assigned-to: —
doc_ref: "—"
---

Ships können Timer setzen (einmalig, Intervall, Timeout) und erhalten Signal via agent-bus beim Ablauf.

Funktionalität:
- ship setzt Timer: starfleetctl timer set <duration> [--repeat] [--label]
- Timer läuft im Hintergrund (daemon/service)
- Bei Ablauf: agent-bus tell <ship> "timer:<label>:expired"
- Unterstützte Formate: 30s, 5m, 1h, 1h30m, oder absolute Zeit (14:30)
- Interval: --repeat / --interval 10m
- Timer auflisten: starfleetctl timer list
- Timer löschen: starfleetctl timer cancel <id>

Akzeptanzkriterien:
- Timer läuft zuverlässig im Hintergrund
- Signal via agent-bus wird korrekt zugestellt
- Mehrere Timer parallel möglich
- Persistenz über Neustarts (optional)
- Integration in starfleetctl CLI
