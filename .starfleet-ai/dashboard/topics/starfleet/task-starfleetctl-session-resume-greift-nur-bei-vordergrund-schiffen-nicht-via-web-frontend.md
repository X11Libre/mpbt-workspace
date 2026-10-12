Title: "starfleetctl: Session-Resume greift nur bei Vordergrund-Schiffen, nicht via Web-Frontend"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-12T13:40:18Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/task-starfleetctl-session-resume-greift-nur-bei-vordergrund-schiffen-nicht-via-web-frontend

Bugreport Praetor (via Defiant m2728). Das Resume-Feature (f81409b: ship-start resumed standardmaessig die letzte Session des Schiffsnamens) funktioniert NUR bei Vordergrund-Schiffen (terminal). Beim Start ueber das Web-Frontend greift der Resume NICHT (neue Session / Kontextverlust).

ERWARTUNG: Resume-Logik (ocsessions.List Title=shipName -> --session an opencode) muss UNABHAENGIG vom Launch-Type/Frontend laufen — d.h. auch fuer Web-/auto-Spawns (LaunchShip muss dieselbe Aufloesung nutzen, bzw. --new nur wenn explizit).

Fix durch LaForge (Source-Owner). Verifikation: Spawn via Web-Frontend nach vorherigem Lauf -> vorheriger Kontext; terminal genauso.
