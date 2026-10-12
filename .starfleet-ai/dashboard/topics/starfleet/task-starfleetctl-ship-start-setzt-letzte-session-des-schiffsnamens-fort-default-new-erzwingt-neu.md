Title: "starfleetctl: Ship-Start setzt letzte Session des Schiffsnamens fort (Default), --new erzwingt neu"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-12T12:50:33Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-starfleetctl-ship-start-setzt-letzte-session-des-schiffsnamens-fort-default-new-erzwingt-neu

Feature-Request Praetor (2026-10-12). Beim Ship-Start (session ship-run UND run --flagship; flagship + normale Schiffe; terminal + background + auto) soll AUTOMATISCH die LETZTE Session zum jeweiligen Schiffsnamen fortgesetzt werden — ausser explizit neue Session gefordert (zusaetzlicher Parameter, z.B. --new/--fresh).

MOTIVATION: Nach Restarts/Abbruechen (heute haeufig) verliert jedes Schiff seinen kompletten Kontext. Agenten sollen ihren vorherigen Gespraechskontext fortsetzen. opencode kann per --continue/--session <id> fortsetzen.

PRAETOR-HINWEIS (Umsetzung): Die letzte Session kann aus der SESSION-LISTE nach dem Schiffsnamen extrahiert werden — das machen wir bereits im Web-Frontend. Also NICHT neu erfinden: dieselbe Session-List-Aufloesung (name -> letzte Session-ID) wiederverwenden, die das Web nutzt.

GEWUENSCHTES VERHALTEN:
- Default: beim Start eines Schiffsnamens die letzte Session dieses Namens laden (resume).
- Explizit neu: Parameter (z.B. --new) erzwingt frische Session.
- Gilt einheitlich fuer session ship-run + run --flagship; terminal/background/auto.

IMPLEMENTATION:
- opencode:  bzw. ; der Starter (internal/session/launch.go, spawnSession + opencode-Aufruf) uebergibt die aufgeloeste Session-ID.
- Session-List-Aufloesung wiederverwenden (dieselbe Quelle wie Web-Frontend /api/sessions mit ship-Name). Keine neue Persistenz noetig, falls die Session-Liste die Zuordnung hergibt.
- Name ist der Schluessel (nicht PID). 'session stop' setzt die Zuordnung NICHT zurueck.
- Fehlt eine gespeicherte Session: normal neu.

AKZEPTANZ: 'ship-run --name X' nach vorherigem Lauf -> vorheriger Kontext; '--name X --new' -> leer. Verifiziert flagship+worker, terminal+background.
