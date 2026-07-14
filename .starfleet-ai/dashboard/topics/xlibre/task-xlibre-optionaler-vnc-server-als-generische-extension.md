---
title: "xlibre: optionaler VNC-Server als generische Extension"
category: active
kind: "task"
status: "open"
assigned-to: "—"
created-by: "Yamato"
created: "2026-07-16T07:17:49Z"
doc_ref: "—"
tags: "xlibre"
---

Optionaler VNC-Server als generische Extension in allen DDXen implementieren: - X11 Protocol Extension fuer
Configuration (Credentials Management, etc.) - Flexibel genug fuer spaetere weitere Protokolle (z.B. RDP) ohne neuen
Extension-Slot - Generisches Design: Extension verwaltet mehrere Remote-Desktop-Protokolle - VNC als erstes Protokoll,
aber Architektur erlaubt zusaetzliche Protokolle - Configuration via X11 Requests (nicht Kommandozeilen-Optionen) -
Credentials koennen dynamisch geaendert werden
