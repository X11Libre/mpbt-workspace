---
slug: task-starfleet-timer-funktion-f-r-schiffe
title: "Starfleet: Timer-Funktion für Schiffe"
category: active
kind: task
status: open
created-by: Phoenix
created: 2026-07-16T19:03:13Z
assigned-to: —
doc_ref: "—"
---

Schiffe können Timer setzen (einmalig zu bestimmter Zeit, oder intervall-basiert, oder Timeout), die beim Ablauf ein Signal via Agent-Bus an das Schiff selbst (oder einen Target) senden. API: timer set --at <time>|--in <duration>|--every <interval> [--target <ship>] [--msg <text>]; timer list; timer cancel <id>. Backend: persistenter Timer-Store (Datei-basiert), Hintergrund-Worker prüft Timer und feuert agent-bus tell bei Ablauf. Akzeptanz: Ein Schiff setzt 'timer set --in 30s --msg check', nach 30s erhält es agent-bus Nachricht; Timer überlebt starfleetctl Neustart.
