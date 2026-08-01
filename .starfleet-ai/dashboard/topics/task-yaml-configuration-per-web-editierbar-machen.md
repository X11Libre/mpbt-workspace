---
slug: task-yaml-configuration-per-web-editierbar-machen
title: "yaml configuration per web editierbar machen"
category: active
kind: task
status: assigned
created-by: Enterprise
created: 2026-08-01T15:28:14Z
assigned-to: Enterprise
doc_ref: "—"
---

YAML-Konfigurationsdateien (project.yaml, fleet.yaml, ship-names.yaml, models.yaml, web.yaml etc.) sollen im Web-UI bearbeitbar sein. WICHTIG: Beim Speichern dürfen vorhandene Kommentare in den YAML-Dateien NICHT zerstört werden. Erfordert einen YAML-Parser der Kommentare beibehält (z.B. go-yaml/v3 mit Comment-Unterstützung oder runde-tripping via yaml.Node).
