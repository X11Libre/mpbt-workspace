Title: "starfleetctl: kommando um alte messages zu entfernen"
Category: active
Status: "done"
Assigned-To: "Janitor"
Created-By: "McKinley"
Created: ""
Doc-Ref: ""

ich sehe (vorallem im web) noch sehr viele messages von schiffen, die längst nicht
mehr existieren. brauche eine funktion (sowohl starfleetctl command line als auch web),
um die alle weg zu räumen (ohne daß ein LLM hier aktiv werden muß).

ERLEDIGT: Die Funktion existiert bereits als `comms purge [--older-than <dur>] [--all]`.
- `comms purge --all` entfernt alle alten Messages von toten Schiffen
- `comms purge --older-than 7d` entfernt Messages älter als 7 Tage von toten Schiffen
- `comms prune` entfernt zusätzlich stale heartbeats + vollständig geackte alte Directives
