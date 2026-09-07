Title: "starfleetctl: rework: kommando um alte messages zu entfernen"
Category: active
Status: "in-progress"
Assigned-To: "McKinley"
Created-By: "McKinley"
Created: ""
Doc-Ref: ""

ERLEDIGT: Die Funktion existiert bereits als `comms purge [--older-than <dur>] [--all]`.
- `comms purge --all` entfernt alle alten Messages von toten Schiffen
- `comms purge --older-than 7d` entfernt Messages älter als 7 Tage von toten Schiffen
- `comms prune` entfernt zusätzlich stale heartbeats + vollständig geackte alte Directives

comms purge --all scheint nicht wirklich wegzuräumen, macht aber eine entsprechende ausgabe. wenn man das mehrfach startet, dann immer wieder die gleiche ausgabe, aber die message files scheinen nach wie vor im spool zu bleibem.
