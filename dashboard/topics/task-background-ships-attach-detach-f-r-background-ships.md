---
slug: task-background-ships-attach-detach-f-r-background-ships
title: "Background-Ships: attach/detach für Background-Ships"
category: active
kind: task
status: open
created-by: Phoenix
created: 2026-07-16T18:23:41Z
assigned-to: —
doc_ref: "—"
---

Konzept und Implementierung für Background-Ships (Sub-Agents, die im Hintergrund laufen und Tasks abarbeiten), die per attach/detach an eine Control-Session angebunden werden können. Ähnlich tmux attach/detach: Background-Ship läuft detached, kann aber per 'starfleetctl session attach <ship>' an eine interaktive Session angebunden werden für Debugging/Steuerung. Benötigt: Session-Management, sichere attach/detach-Synchronisation (Mutex, keine Race-Conditions), Persistierung des Background-State. Akzeptanz: Background-Ship startet detached, führt Task aus, kann per attach angezeigt werden, detach funktioniert sauber ohne Absturz.
