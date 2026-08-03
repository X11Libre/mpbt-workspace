Title: "Terminologie: 'agents' → 'ships' wo passend"
Category: parked
Noted-By: "Enterprise"
Since: "2026-08-02"

Review of every "agents" occurrence in the starfleetctl repo (SOP-rename
follow-up). NOT started: Stargazer is currently working in starfleetctl —
coordinate before editing. Everything below is analysis only.

== Klar: "agents" meint die Flotten-Schiffe → "ships" (User-facing / help) ==
- cmd/starfleetctl/main.go:64  help "temporary file store for agents" → "for ships"
- internal/comms/commands.go:536  "(no agents reporting …)" → "(no ships reporting)"
- internal/session/run.go:92  "(no agents reporting)" → "(no ships reporting)"

== Klar: Doc-Kommentare, die die Schiffe meinen → "ships" ==
- internal/bootstrap/checks.go:90  "so agents load the current index"
- internal/bootstrap/checks.go:99  "so every bootstrap keeps agents in sync"
- internal/bridged/protocol.go:37  "agents' identities"
- internal/comms/comms.go:285  "number of agents who have acked"
- internal/comms/json.go:5  "so agents consuming this output"
- internal/dashboard/bootstrap.go:14  "lets parallel agents"
- internal/filestore/filestore.go:4,6  "fleet agents" / "Agents upload"
- internal/sop/agents.go:101  "so that agents which don't resolve @-imports"
- internal/sop/commands.go:166  "entry point for agents that don't resolve @-imports"
- internal/sop/lock.go:18  "Go agents commit and a concurrent bash/Go actor"
- internal/timer/types.go:18  "fire comms directives to agents"

== Historische Referenz (altes Paket) ==
- internal/flock/flock.go:15  "lived in comms/prclaim/dashboard/agents/shipnames/"
  → "agents" war der alte Paketname → jetzt "sop" (nicht "ships")

== Doku: überwiegend "ships" passender (Flotten-Doku) ==
- doc/architecture.md:7,67,113,122  (generic "AI agents" ok, "ships" konsistenter)
- doc/dashboard.md:14,102  "two agents racing/committing" → ships
- doc/pr-claim.md:18,20  "Each agent works in its own clone"
- doc/sop.md:193,223  "How Agents Receive Fragment Content"
- doc/USER.md:129  "all participating agents check claims"
- doc/web-ui.md:177  "/api/board … all agents with status" → "all ships"
- README.md:5,9,12,13  "concurrent agent sessions ("ships")" — equates agents=ships

== Bewusst KEEPEN ("agents" = legitimer Begriff) ==
- Legacy `agents.d/`-Pfade + `agents`-Legacy-Alias (cmd/main.go:69,235; checks.go; sop/*; doc/sop.md)
- AGENTS.md-Dateien, `agent_config`-Verzeichnis, `agent_permission_hook`, `agent_subdir`
  (projectconfig — published config key, rename wäre breaking), opencode/Claude "agents" (SDK etc.)
- doc/session.md:72 "Spawn additional agents" — meint Sub-Agents, NICHT Schiffe
- doc/reports.md:3 "submitted by ships (agents)" — schon beides
- internal/comms/monitor.go agentSafe/pidFile — interne Variablen, optional "shipSafe"

== Fragment (Sonderfall, braucht Stale-Cleanup) ==
- fragments/starfleet-instructions/working-practices-standing-instructions-for-agents.md
  Slug+Titel enthalten "for-agents" → z.B. "working-practices-for-ships". Umbenennen
  erzeugt Stale-Fragment in var/sop.d/starfleet-instructions/ → Cleanup in
  DoInstallStarfleet/verifyStarfleetFragments nötig (wenn gewünscht).

Vorschlag: erst Stargazer fertig werden lassen (comms abstimmen), dann ein Thema nach
dem anderen committen. User-facing strings + Doc-Kommentare zuerst (risikofrei), Doku
danach, Fragment-Umbenennung zuletzt.
