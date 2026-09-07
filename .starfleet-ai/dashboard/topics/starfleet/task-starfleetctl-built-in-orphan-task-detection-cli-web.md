Title: "starfleetctl: built-in orphan-task detection (CLI + Web)"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "Voyager"
Created-By: "Enterprise"
Created: "2026-09-07T09:21:34Z"
Doc-Ref: "—"

Neues Feature: starfleetctl soll eingebaut Tasks erkennen, die an nicht mehr existierende Schiffe zugewiesen sind (kein Status-/Health-Eintrag / nicht im Board). Ablauf wie manuell am 2026-09-07: alle Dashboard-Topics laden, Assigned-To mit aktueller Schiffsliste (comms board/status/health) abgleichen.  CLI: Subcommand (z.B. 'task orphans', optional --json) listet Orphan-Tasks (slug, assigned-to, status).  Web: API-Endpoint (z.B. GET /api/tasks/orphans) + UI-View/Button auf Tasks-Seite zum Anzeigen + One-Click-Reassign an freies Schiff.  Referenz-Orphans von 2026-09-07: Stargazer (4: task-capture-first-status-board, error-handling-1, refactoring-git, web-frontend-bug-terminal), Miranda (11 pr-submitted: os.h-*/compiler.h-*), Saratoga (2 analysis-done).  WICHTIG: nur 1 Schiff gleichzeitig am starfleetctl-Source — mit Galactica (capture-first) + Aeon (error-handling/refactoring-git) abstimmen. Deployment via make + starfleet-bootstrap. Report an Enterprise.

**Progress (Voyager 2026-09-07):** Implementierung + Tests fertig & gruen. CLI `task orphans [--json]` (FindOrphans in internal/task), Web-API GET /api/tasks/orphans, Web-UI-Button "Orphans" auf Tasks-Seite mit One-Click-Reassign (__auto__ -> Flagschiff-Delegation oder explizites Idle-Schiff-Dropdown). Unit-Tests internal/task + internal/web gruen, `make all` gruen. Skill-Reference + SKILL.md aktualisiert. Committet von Enterprise als b5f3f2c (Enrico, master). Deployed via starfleet-bootstrap (Worker+Web-Restart). Verifiziert: CLI zeigt 4 Orphans, Web HTTP 200 + /api/tasks/orphans liefert JSON. Task done.
