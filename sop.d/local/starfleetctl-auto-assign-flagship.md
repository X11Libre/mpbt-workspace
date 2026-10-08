---
slug: local/starfleetctl-auto-assign-flagship
title: "starfleetctl: auto-assign → Flagschiff (Delegation)"
order: 20
---

# starfleetctl: auto-assign → Flagschiff (Delegation)

Gelernt beim Diagnose/Fix der Web-Auto-Zuweisung (2026-07-31).

**Verweis:** Auto-Assign-Verhalten (`--assign auto` routet immer zum Flagschiff) ist vollständig
im Skill `workspace-auto-assign` dokumentiert (`.claude/skills/workspace-auto-assign/SKILL.md`).

## Kernfakten (Kurzfassung)

- **Fix (Commit f84d312):** Auto-Assign (`task capture --assign`, `task assign` ohne Ship, Web
  `__auto__`) routet **immer zum Flagschiff** (`shipnames.FlagshipName(root)`, hier Enterprise),
  das delegiert oder selbst bearbeitet. `pickFreeShip` entfernt (früher wählte es die Web-Console
  selbst → Self-Assign-Fehlbild).
- Web-`created-by` ist immer die Console-Identität (web.yaml `ship_id`; web.go setzt
  `STARFLEET_SHIP_ID` beim Start) — **gewollt**.
- `ws-commit <pfad>` schlägt fehl für Pfade unter einem gitignorierten Verzeichnis
  (`.claude/skills/starfleet`) → dann `ws-commit -a` nutzen.

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