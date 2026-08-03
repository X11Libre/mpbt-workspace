Title: "Terminologie: 'agents' → 'ships' wo passend"
Category: done
Status: "assigned"
Assigned-To: "Stargazer"
Created-By: ""
Created: ""
Doc-Ref: ""

Review of every "agents" occurrence in the starfleetctl repo (SOP-rename
follow-up). Implemented and deployed 2026-08-03 (commits e5f1af1, f56ca56,
b2c1f27 on starfleetctl master; bootstrap + web/timer restarted, HTTP 200).

== Umgesetzt ==
- User-facing/help: "temporary file store for ships", "(no ships reporting)"
  (main.go, comms/commands.go, session/run.go)
- Doc-Kommentare in bootstrap/bridged/comms/dashboard/filestore/sop/timer → "ships"
- flock.go historische Paketliste → "sop"
- Doku: README.md, doc/architecture.md, doc/dashboard.md, doc/pr-claim.md,
  doc/sop.md, doc/USER.md, doc/web-ui.md → "ships"
- Fragment umbenannt: working-practices-standing-instructions-for-agents →
  working-practices-for-ships (Datei + Slug + Titel); DoInstallStarfleet entfernt
  nun verwaiste installierte Fragmente (Stale-Cleanup) — verifiziert: altes
  Fragment aus var/sop.d entfernt, neues installiert + indexiert.

== Bewusst KEEPEN ("agents" = legitimer Begriff) ==
- Legacy `agents.d/`-Pfade + `agents`-Legacy-Alias (cmd/main.go:69,235)
- AGENTS.md-Dateien, `agent_config`-Verzeichnis, `agent_permission_hook`,
  `agent_subdir` (projectconfig — published config key, rename wäre breaking),
  opencode/Claude "agents" (SDK etc.)
- doc/session.md "Spawn additional agents" — Sub-Agents, NICHT Schiffe
- doc/reports.md "ships (agents)" — schon beides
- internal/comms/monitor.go agentSafe/pidFile — interne Variablen (optional "shipSafe")
