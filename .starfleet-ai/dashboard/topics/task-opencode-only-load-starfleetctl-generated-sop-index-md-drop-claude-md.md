Title: "opencode: only load starfleetctl-generated SOP index.md (drop CLAUDE.md)"
Category: active
Kind: task
Status: "assigned"
Created-By: "unknown"
Created: "2026-11-06T12:35:19Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: task-opencode-only-load-starfleetctl-generated-sop-index-md-drop-claude-md

Ziel
====
In jeder opencode-Ship-Session darf ausschließlich der von `starfleetctl` generierte SOP-Index geladen werden:
`.starfleet-ai/var/sop.d/index.md` — genau einmal, immer, und ausschließlich aus den via `starfleetctl` verwalteten SOP-Fragmenten erzeugt (`sop reindex`).

Das lokale `CLAUDE.md` im Workspace-Root soll als Instruction-Quelle entfallen. Es darf von opencode nicht mehr automatisch geladen werden.

Problem
=======
opencode 1.19.3 lädt aktuell zwei Kopien derselben SOP:

1. `.starfleet-ai/var/sop.d/index.md` via `instructions` in der Ship-Config (`$OPENCODE_CONFIG`, `.starfleet-ai/var/ships/*.opencode.json`).
2. `CLAUDE.md` via Projekt-Regel-Auto-Discovery: Reihenfolge `AGENTS.md` → `CLAUDE.md` → `CONTEXT.md`; erster gefundener Name gewinnt; `findUp` bis zum Git-Worktree. Im Worktree `/home/nekrad/src/xorg/mpbt-workspace` gibt es kein `AGENTS.md`, also wird `CLAUDE.md` geladen.

Beide Dateien werden von `sop reindex` erzeugt und haben identische Bodies (aktuell 95.555 B bzw. 95.906 B, Body-SHA `b4f6919003c2b163`). Das sind ca. 24k zusätzliche Input-Tokens pro Request.

Evidenz
=======
- opencode 1.19.3 `Instruction.systemPaths`: lokale Regeln in Reihenfolge `AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`; `findUp` ist auf `d.worktree` begrenzt. `instructions`-Einträge werden separat per `globUp` aufgelöst und demselben Set hinzugefügt; es gibt keine Inhalts-Deduplizierung.
- Workspace ist eigener Git-Worktree; `CLAUDE.md` vorhanden, `AGENTS.md` fehlt.
- Relevanter Code: `internal/sop/commands.go:133-181` (`DoReindex` schreibt `index.md` + `CLAUDE.md`), `internal/sop/agents.go`, `internal/session/launch.go:1197`, `internal/session/run_cmd.go:166-171`, `internal/bootstrap/checks.go:85/864-889`, `internal/timer/system.go:32-54`, `cmd/starfleetctl/main.go` (`workspaceRoot`-Landmark), `.opencode/plugins/starfleet-dispatch.ts:823`, `doc/sop.md`, `doc/USER.md`.

Anforderungen
=============
1. opencode lädt nur noch `index.md`, nie `CLAUDE.md`. Bevorzugt: `DoReindex` erzeugt keine volle `CLAUDE.md`-Kopie mehr; entferne `CLAUDE.md` aus dem Workspace-Root und alle Generierungs-/Commit-Pfade dafür. Falls Claude Code weiter unterstützt wird: dünner `CLAUDE.md`-Pointer mit `@.starfleet-ai/var/sop.d/index.md` **und** opencode-seitig `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1`.
2. `index.md` bleibt die einzige always-on-Instruction-Quelle und wird immer geladen: `instructions` muss in allen Ship-Configs und allen Launch-Pfaden exakt `.starfleet-ai/var/sop.d/index.md` enthalten.
3. Robuste, idempotente Lösung im starfleetctl (kein lokaler Workspace-Hack): Setze für opencode-Launches `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1` (alle Pfade: terminal, auto, background, `run --exec`, supervisor) **oder** sorge dafür, dass gar kein `CLAUDE.md` mehr existiert. Variante wählen, begründen, testen.
4. `bootstrap --fix`, `genesis-init`, `sop reindex`, `install-starfleet`, `self-install` müssen idempotent sein und den Doppel-Load nicht wieder einführen.
5. Tests anpassen/ergänzen (`internal/sop/*_test.go`, `internal/bootstrap/*_test.go`, ggf. `internal/session`), `go test ./...` grün.
6. Doku aktualisieren (`doc/sop.md`, `doc/USER.md`, Code-Kommentare): Agent-Instructions kommen **immer** aus den starfleetctl-verwalteten SOP-Fragmenten.
7. Kurzer Vorher/Nachher-Bericht (Prompt-/Token-Größe; erwartet ca. 24k Tokens/Request weniger).

Akzeptanzkriterien
===================
- Frische opencode-Ship-Session im Workspace-Root: System-Prompt enthält `Instructions from: .starfleet-ai/var/sop.d/index.md` genau einmal und **kein** `Instructions from: .../CLAUDE.md`.
- `CLAUDE.md` ist entfernt oder ein dünner, von opencode nicht geladener Pointer.
- Alle `*.opencode.json` haben `instructions: [".starfleet-ai/var/sop.d/index.md"]`.
- `starfleetctl bootstrap --fix` und `sop reindex` mehrfach ausführbar, ohne den Doppel-Load wiederherzustellen.
- Alle Launch-Modi laden `index.md`.
- `go test ./...` grün; Doku aktualisiert.

Constraints
===========
- Keine Änderungen an den Workspace-SOP-Fragmenten für diese Aufgabe (Tool-Fix).
- Kein handgepflegter Instruction-Content; `index.md` wird ausschließlich von `sop reindex` aus den Fragmenten erzeugt.
- Kanonisches Repo: `_WORK_/starfleetctl/sources/starfleetctl` (gleicher Stand wie deployed); Branch/PR, nicht direkt auf `main` pushen.
- Claude Code, falls weiter unterstützt, nicht brechen: dünner Pointer/`@`-Import statt Vollkopie; opencode muss ihn trotzdem ignorieren.
- Keine Secrets in Task/Commits.

Verifikation
============
- `rg -n "CLAUDE\\.md|index\\.md"` im starfleetctl-Repo; betroffene Stellen prüfen.
- Frische Session/Throwaway-Ship zum Messen; alternativ Prompt-Größe über Model-Proxy-Logs.
- `go test ./...`.
