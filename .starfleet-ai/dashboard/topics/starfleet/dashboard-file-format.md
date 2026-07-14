---
title: "dashboard file format auf rfc288-stil umstellen"
category: active
kind: "task"
status: "assigned"
assigned-to: "Agamemnon"
created-by: ""
created: ""
doc_ref: ""
tags: "starfleet"
---

Umstellung des File-Format für das Dashboard im RFC288-Stil.
Fehlende header werden automatisch mit einem sinnvollen Default-Wert angenommen.
Wenn zb. das State-Feld fehlt, dann ist das ein neu eingestellter Task
(der evtl. auch manuell eingestellt wurde)

* support für neues Format -- incl. doku / skills im starfleet anpassen
* migration der existierenden einträge & reindex
* support für altes Format entfernen
* dokumentation und skills im starfleet anpassen & neu bauen & ausrollen
