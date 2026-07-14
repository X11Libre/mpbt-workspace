---
slug: task-reports-kurzansicht-markdown-task-referenz-attachments
title: "Reports: Kurzansicht, Markdown, Task-Referenz, Attachments"
category: active
kind: task
status: done
created-by: Enterprise
created: 2026-07-30T09:07:44Z
assigned-to: Phoenix
completed: 2026-07-30T09:35:00Z
doc_ref: "internal/web/index.html:1240-1294"
---

Berichte-System ausbauen: 1) Liste zeigt nur Kurzansicht (subtitle-Feld optional) 2) Klick → Vollansicht mit Markdown-Rendering 3) Timestamp-Feld 4) Optionaler Verweis auf Dashboard-Task (verlinkt im Web) 5) File-Attachments via filestore (verlinkt, im Browser anschaubar)

Alle 5 Anforderungen waren bereits im Reportsystem (commit 3fbf27b + 83a322c) implementiert:
- Kurzansicht: Liste zeigt Titel + Subtitle + Ship + Ago + Tags, body nur im Modal
- Markdown: mdHtml() in openRepModal() rendert body
- Timestamp: ago in Listenkarte, created in Modal-Meta
- Task-Ref: task_ref als verlinkter Klick im Modal → showTaskFromReport()
- Attachments: /api/store/ Links im Modal, Upload via POST /api/store/<name>
