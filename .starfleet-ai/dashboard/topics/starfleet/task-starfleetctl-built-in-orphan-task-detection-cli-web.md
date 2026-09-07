Title: "starfleetctl: built-in orphan-task detection (CLI + Web)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-07T09:21:34Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-starfleetctl-built-in-orphan-task-detection-cli-web

Neues Feature: starfleetctl soll eingebaut Tasks erkennen, die an nicht mehr existierende Schiffe zugewiesen sind (kein Status-/Health-Eintrag / nicht im Board). Ablauf wie manuell am 2026-09-07: alle Dashboard-Topics laden, Assigned-To mit aktueller Schiffsliste (comms board/status/health) abgleichen.  CLI: Subcommand (z.B. 'task orphans', optional --json) listet Orphan-Tasks (slug, assigned-to, status).  Web: API-Endpoint (z.B. GET /api/tasks/orphans) + UI-View/Button auf Tasks-Seite zum Anzeigen + One-Click-Reassign an freies Schiff.  Referenz-Orphans von 2026-09-07: Stargazer (4: task-capture-first-status-board, error-handling-1, refactoring-git, web-frontend-bug-terminal), Miranda (11 pr-submitted: os.h-*/compiler.h-*), Saratoga (2 analysis-done).  WICHTIG: nur 1 Schiff gleichzeitig am starfleetctl-Source — mit Galactica (capture-first) + Aeon (error-handling/refactoring-git) abstimmen. Deployment via make + starfleet-bootstrap. Report an Enterprise.
