---
slug: local/session-state-2026-10-08-voyager
title: "Session-State Voyager — 2026-10-08 (Web-Frontend-Reparatur)"
order: 0
---

# Session-State Voyager — 2026-10-08

Auftrag des Praetors: **Web-Frontend reparieren** ("zeigt keine Schiffe mehr an,
nichts anklickbar"), danach abstimmen mit Enterprise. Danach: Flotte wird komplett
neu gestartet — dieser Zustand dient dem Wiedereinstieg.

## Erledigt (web-frontend)

**Symptom:** `/` liefert 200, `/api/board` liefert volles JSON — Board bleibt
trotzdem leer, keine Interaktivitaet.

**Zwei Ursachen, beide aus Commit `1a23e4b` (2026-10-06, "add URL linkification"):**

1. **escAttr-Syntaxfehler (kritisch).**
   `internal/web/index.html` Zeile 961:
   `function escAttr(s){ return esc(s).replace(/"/g,'"').replace(/'/g,'''); }`
   Die HTML-Entities `&quot;`/`&#39;` wurden zu literalen Zeichen dekodiert ->
   `'''` -> SyntaxError -> der EINE inline `<script>`-Block parst nicht ->
   kein `refresh()`, keine Klickhandler. Seite ist eine Leiche (HTML/CSS rendern).
   **Fix:** `5f0bdfc` (LaForge) — Entities zurueckgesetzt.

2. **linkifyURLs Doppelt-Escaping (Folgfehler).**
   `linkifyURLs()` lief auf bereits `esc()`tem HTML und escaped erneut ->
   jedes `&` in URLs wurde `&amp;amp;`.
   **Fix:** `a781d43` — arbeitet auf ROHEM Text, escaped genau einmal;
   `linkifyAttach()` uebergibt rohe Slices.

**Beide Fixes:** committed + signed-off, auf `origin/master`, deployed via
`./starfleet-bootstrap`, `web restart` + `timer worker restart`.

**Verifikation (alles gruen):**
HTTP 200 auf `/`, `/api/models`, `/api/board`, `/api/ships`; ausgeliefertes Script
parst (`node --check`); 0x `'''`; headless Chromium: render + click(Overlay) +
`history.back()`(popstate) + Tab-Wechsel + 0 JS-Exceptions.

**Ueberwachung / Werkzeuge (versioniert):**
- `scripts/web-frontend-check.sh [base-url]` — 3 Schichten (HTTP / Source-Parse /
  Browser-E2E). Exit 0 = gesund.
- `scripts/web-frontend-browser-check.mjs` — CDP-Test (node `ws`, kein Puppeteer).
- Commit `16b3adaa4a` im Workspace-Repo.
- Timer `wild-sky-38` (Owner Enterprise, alle 30 min) prueft HTTP + `'''` + node-Parse
  und meldet nur bei Fehler. Praetor wuenschte zusaetzlich einen stuendlichen Test —
  `wild-sky-38` deckt das inhaltlich ab; bei Bedarf eigenen stuendlichen Timer setzen.

## Wichtige Messwerte / Nebenwirkung des `.starfleet-ai`-Wipes

- `.starfleet-ai` war zwischenzeitlich weg; der Praetor hat es zurueckgeholt.
  Ein Restore aus Git holt `conf/`, `dashboard/topics/` und SOPs — **nicht** `var/`.
- **`/api/models` = 503** ("no model proxy configuration") bedeutet:
  `.starfleet-ai/conf/model-proxy.yaml` fehlt (Handler liest pro Request).
  Nach Restore von `conf/` sofort wieder 200, ohne Restart.
- **Terminals aller laufenden Schiffe unerreichbar** (`/api/ship/<name>/screen|dimensions|x11term`
  -> 404 "no running terminal"): die termctl-FIFOs liegen in
  `.starfleet-ai/var/ships/<ship>.pipe` und sind ephemer. Ein extern neu erzeugtes
  FIFO reconnected NICHT (anderer Inode; Server haelt seinen Inode). **Reparatur nur
  per Session-Neustart des jeweiligen Schiffs.**

## Offen / nach dem Flotten-Neustart zu klaeren

1. **Ursache des `.starfleet-ai`-Wipes nicht abschliessend geklaert.** Zeitlich faellt
   er mit einem `./starfleet-bootstrap` (self-install + `bootstrap --fix`) zusammen;
   der Bootstrap-Script selbst loescht nur bei `--clean`. Verdacht: eine
   self-install/`projectconfig`-Migration (Commits `6191141`, `3ce5e1f`, `04f0eba`).
   Nicht bewiesen — nach dem Neustart nachmessen, bevor jemand beschuldigt wird.
2. Wachen, dass nach dem Flotten-Neustart **alle Pipes** wieder da sind
   (`.starfleet-ai/var/ships/*.pipe`) und die Terminals erreichbar sind.
3. `scripts/web-frontend-check.sh` nach dem Neustart erneut laufen lassen.
4. Kein Doppel-Commit: LaForge ist Source-Owner von starfleetctl. Beide Fixes hat er
   committet (nach meiner Analyse/Vorlage) — Koordination lief ueber comms (m131426).

## Wichtige Pfade / Referenzen

- Repo-Source (LaForge-Hoheit, nur lesen): `_WORK_/starfleetctl/sources/starfleetctl`
- Deployter Clone: `.starfleet-ai/src/starfleetctl` (Bootstrap: git pull origin/master)
- Web-Frontend: `internal/web/index.html` (go:embed, EIN `<script>`-Block)
- Lessons dieses Vorfalls: `sop.d/local/local-knowledge-dump.md` (drei neue Abschnitte)
- State-Fragment fuer Enterprise: `sop.d/local/session-state-2026-09-16-1930.md` (Vorgaenger)
