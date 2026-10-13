Title: "session-restart: Fertigstellung ueberwachen + Praetor melden"
Category: active
Kind: task
Status: "open"
Created-By: "Defiant"
Created: "2026-10-13T09:11:55Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-session-restart-fertigstellung-ueberwachen-praetor-melden

Praetor-Auftrag: Bescheid geben, wenn das Remote-Restart-Feature komplett fertig ist. Owner der Implementierung: LaForge (starfleetctl-Source). Stand: Kern (UDS-Control RESTART/STOP/STATUS, Modellwechsel, Child-Lifecycle) in 2f4b4cf implementiert+deployed; Web-API POST /api/ships/<name>/restart + CLI 'ship restart' noch offen (LaForge next steps). Defiant ueberwacht via Timer mild-moon-44 und meldet bei Fertigstellung.
