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

## opencode-plugin Build-Test (Makefile `check-plugin`, Commit 8dee257, 2026-07-31)

- Plugin `fragments/opencode-plugins/starfleet-dispatch.ts` importiert nur
  `node:child_process` — standalone, `types:["node"]` reicht für tsc komplett.
- Bootstrap (`internal/bootstrap/checks.go` `verifyOpencodePlugins`): deployed nur
  `.ts`-Dateien byte-identisch nach `.opencode/plugins/` + Registry in
  `.opencode/opencode.json` `plugin`-Array. Ein `tsconfig.json` im Plugin-Dir wird
  embedded aber **nicht** deployed/geprüft — sicher, dort abzulegen.
- `scripts/check-opencode-plugin.sh`: esbuild-Bundlecheck (Pflicht wenn esbuild da)
  + `tsc --noEmit` (nur wenn typescript UND @types/node auflösbar, sonst skip mit
  Hinweis → `make all` bleibt auf Hosts ohne node grün). In `make all` eingehängt.
- TypeScript v7.0.2-Getchas: `--typeRoots` als CLI-Flag wird **ignoriert** (TS5108:
  `moduleResolution node10` entfernt → `bundler` nutzen); `typeRoots`/`types`
  auflösen läuft **ab dem tsconfig-Ort nach oben** — temporäre tsconfigs in `/tmp`
  finden `node_modules/@types` nicht (Test also im Repo ablegen).
- Host-Bestand: `/bin/esbuild` v0.25.5, node v20.19.2; `tsc` global NICHT installiert,
  npx-Registry offline. Caches: typescript v7.0.2 unter
  `/home/nekrad/.npm/_npx/11d9e06b573ee33f/node_modules/typescript`,
  `@types/node` unter `/home/nekrad/.npm/_npx/e5f4bcd55d2c7c9f/node_modules/@types`
  (für Validierung per Symlink nach `node_modules/` einspielen, danach entfernen).
- Optionale Harness-/Unit-Test-Idee (Topic-Vorschlag 3) bewusst **nicht** umgesetzt —
  esbuild+tsc decken Syntax/Imports/Typen ab; Plugin-Logik-Test wäre eigener Task.
