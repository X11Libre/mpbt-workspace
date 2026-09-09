---
slug: local/starfleetctl-auto-assign-flagship
title: "starfleetctl: auto-assign → Flagschiff (Delegation)"
order: 20
---

# starfleetctl: auto-assign → Flagschiff (Delegation)

Gelernt beim Diagnose/Fix der Web-Auto-Zuweisung (2026-07-31).

## Der Self-Assign-Bug

- Die Web-Console trägt sich auf dem Bus unter der in `.starfleet-ai/conf/web.yaml`
  konfigurierten `web.ship_id` (hier `McKinley`) ein — unabhängig davon, mit welcher
  `STARFLEET_SHIP_ID` der Server gestartet wurde (`internal/web/web.go` `New()`
  macht `os.Setenv("STARFLEET_SHIP_ID", shipID)`).
- Beim Betrachten setzt die Console ihr Ship auf `idle` (Log: `comms: 'McKinley' → idle — web console`).
- Der alte Auto-Assign (`pickFreeShip`: erster idle+non-stale Ship vom Board) wählte
  dadurch **die Console selbst** → Task sah aus wie Selbstzuweisung
  (`created-by: McKinley` + `assigned-to: McKinley`). Dazu: Toast zeigte literal `__auto__`.

## Fix (starfleetctl-Repo, Commit f84d312)

- Auto-Assign (`task capture --assign`, `task assign <slug>` ohne Ship, Web `__auto__`)
  routet jetzt **immer zum Flagschiff** (`shipnames.FlagshipName(root)`, hier Enterprise),
  das delegiert oder selbst bearbeitet. `pickFreeShip` entfernt.
- `commissionShip`: Message ans Flagschiff enthält explizit den Delegations-Hinweis
  ("kann an einen freien Worker delegieren, z.B. via `task assign <slug> <ship>`").
- UX: Web-Labels/Toasts zeigen "Flagschiff (delegiert)" statt des Sentinels.

## Details / Stolperfallen

- Web-`created-by` ist immer die Console-Identität (web.yaml `ship_id`) — gewollt.
- `ws-commit <pfad>` schlägt fehl, wenn der Pfad unter einem gitignorierten Verzeichnis
  liegt (`.claude/skills/starfleet` ist getrackt aber dir-weit ignoriert) → dann `ws-commit -a` nutzen.
- End-to-End-Webtest-Muster: Wegwerf-Task via `POST /api/task` mit `assign:"__auto__"`,
  Ergebnis im `/api/tasks` prüfen, dann `task rm` + aufräumen.

## opencode-plugin Build-Test (Makefile `check-plugin`, Commit 8dee257)

- `scripts/check-opencode-plugin.sh`: esbuild-Bundlecheck + `tsc --noEmit` (nur wenn
  typescript UND @types/node auflösbar, sonst skip → `make all` bleibt ohne node grün).
- Bootstrap deployed nur `.ts`-Dateien byte-identisch nach `.opencode/plugins/`; ein
  `tsconfig.json` im Plugin-Dir wird embedded aber **nicht** deployed/geprüft.
- TypeScript v7 ähnlich `--typeRoots` als CLI-Flag wird **ignoriert** →
  `moduleResolution bundler` nutzen; Tests nicht in `/tmp` (typeRoots lösen ab dem
  tsconfig-Ort nach oben auf, finden `node_modules/@types` nicht).

*(Host-spezifische Tooling-Details von 2026-07-31 — esbuild/node-Versionen, npx-Caches —
bewusst entfernt; in Git-History nachschlagbar.)*