---
slug: task-terminal-aa-detach-race-condition-bei-attach-detach-beheben
title: "terminal-aa-detach: Race Condition bei attach/detach beheben"
category: active
kind: task
status: open
created-by: Yamato
created: 2026-07-15T15:14:50Z
assigned-to: —
doc_ref: "—"
---

Bei Tests mit dem aktuellen Stand funktioniert attach/detach manchmal nicht. Verdacht: Race Conditions im Code. Moegliche Probleme: 1) Keine Synchronisation zwischen attach/detach und Event-Loop 2) 'attached' Flag wird ohne Lock geaendert 3) conn.Events() kann auf geschlossener Connection aufgerufen werden 4) Mehrere Signals/Commands koennen gleichzeitig kommen. Zu pruefen: Mutex fuer attached-Flag, Synchronisation von attach/detach mit Event-Loop, sichere Behandlung von conn.Events() nach Close.
