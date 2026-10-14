Title: "Analyse der geparkten WIP fix/zen-session-header (commit eec3db2)"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-14T09:53:57Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/task-analyse-wip-fix-zen-session-header

Geparkte WIP analysieren: was tut sie, wird sie noch gebraucht?

Kontext: Im (ehemaligen) Worktree cb-recovery lagen uncommittete Aenderungen, die
Enterprise gesichert hat:
- Branch: fix/zen-session-header
- Commit: eec3db2 "fix(model-proxy): never fabricate x-opencode-session for opencode-zen"
- Dateien: internal/config/config.go, internal/modelproxy/config.go, internal/modelproxy/config_test.go
- Inhalt: appliziert fuer opencode-zen keine erfundene Session-Id (ses_<rand>) mehr,
  sondern bevorzugt Client-Session -> konfigurierte Provider-SessionID -> gar keins.
  Grund: Zen-Free-Tier lehnt fabrizierte Session-IDs mit HTTP 403 (FreeTierError) ab.
- Code-Teil der Branch-Basis (d504baa circuit-breaker auto-recovery, 3a7b010 semantic
  split direct providers) ist bereits in master; einzigartig ist nur eec3db2.

Aufgabe:
1) Analysieren, ob dieser Fix korrekt/aktuell ist und ob er gebraucht wird
   (Abgleich mit dem inzwischen gemergten Verhalten von applyUpstreamHeaders).
2) Entscheiden: mergen, anpassen oder verwerfen.
3) Ergebnis ins Topic / an Enterprise melden.

Hinweis: Author-Feld des Commits ist vorlaeufig auf LaForge gesetzt (reine Annahme) —
bitte ggf. korrigieren.
