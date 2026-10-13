Title: "session-restart: Fertigstellung ueberwachen + Praetor melden"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "—"
Created-By: "Defiant"
Created: "2026-10-13T09:11:55Z"
Doc-Ref: "—"

Praetor-Auftrag: Bescheid geben, wenn das Remote-Restart-Feature komplett fertig ist. Owner der Implementierung: LaForge (starfleetctl-Source). Stand: Kern (UDS-Control RESTART/STOP/STATUS, Modellwechsel, Child-Lifecycle) in 2f4b4cf implementiert+deployed; Web-API POST /api/ships/<name>/restart + CLI 'ship restart' noch offen (LaForge next steps). Defiant ueberwacht via Timer mild-moon-44 und meldet bei Fertigstellung.

- 2026-10-13T10:56:10Z Defiant: completed

- 2026-10-13T11:14:26Z Defiant: E2E-Test auf LaForge FEHLGESCHLAGEN: LaForge.soc existiert (12:53) aber kein Listener; Parent pid 11152 = 0 Sockets + deleted Binary. Ursache: stale Socket vom Respawn nicht bereinigt, neuer Parent band nicht neu. LaForge bestaetigt + fixt (robustes Remove+Listen beim Start). Route/Code deployed. Erneutes Warten auf E2E-Bestaetigung (Timer iron-wind-65).

- 2026-10-13T11:37:09Z Defiant: LaForge-Status (m4266): Fix groesser als stale-socket — (1) RESTART signalisiert nur Channel, restartet Kind nicht; (2) STOP killt Kind nicht; (3) Supervisor-Leak (select-Block kehrt bei restart zurueck). Rework LaunchShip (child-PID, inline restart), ETA naechste Session. Feature also noch nicht fertig.
