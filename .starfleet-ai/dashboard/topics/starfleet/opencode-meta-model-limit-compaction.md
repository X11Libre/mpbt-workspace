---
title: "opencode: Meta-Model-Eintraege ohne limit.context — Auto-Compaction + Overflow-Selbstheilung tot"
category: active
kind: "task"
status: "open"
assigned-to: "—"
tags: "starfleet,opencode,config,compaction"
---

## Problem

Alle generierten Ship-Configs (`.starfleet-ai/var/ships/*.opencode.json`) haben in
`provider.meta-model.models.<strategie>` **keinen `limit`-Eintrag**:

```json
"meta-model": { "models": {
  "heavy-model": { "name": "Dreadnought", "temperature": true, "tool_call": true },
  ...
}}
```

Vergleich: `provider.zen-proxy.models.big-pickle` traegt korrekt
`{"context": 200000, "output": 32000}`.

## Symptome (gemessen)

1. **Sidebar zeigt "0% used"** — opencode rechnet die Auslastung gegen
   `models.<id>.limit.context`; ohne Limit keine Prozentanzeige (Defiant auf
   `heavy-model`: 146k Tokens, 0%. Enterprise auf `zen-proxy/big-pickle`:
   130k @ 65% ⇒ 200k-Fenster — Anzeige stimmt dort).
2. **Proaktive Auto-Compaction deaktivert.** Code-Extrakt aus
   `~/.local/lib/node_modules/opencode-ai/bin/opencode.exe` (SessionCompaction):

   ```js
   compactIfNeeded(req):
     if (!config.auto) return false;
     let limit = req.model.route.defaults.limits?.context;
     if (limit === undefined || limit <= 0) return false;   // <-- harte Sperre
     if (requestTokens <= limit - max(outputLimit, buffer)) return false;
     return compactAfterOverflow(req);

   compactAfterOverflow(req):          // wird AUCH bei Upstream-Overflow-Fehler aufgerufen
     let limit = req.model.route.defaults.limits?.context;
     if (limit === undefined || limit <= 0) return false;   // <-- harte Sperre
     if (estimate(compacted) > limit - maxTokens) return false;
     ...
   ```

3. **Reaktive Overflow-Selbstheilung tot — gleicher Guard.** Wenn der Upstream
   mit "maximum context length" ablehnt, klassifiziert opencode das per Regex
   als `context-overflow` und ruft `compactAfterOverflow` — der bricht am
   selben `limit <= 0`-Guard ab. Ergebnis: **harter Turn-Abbruch statt
   Compaction** (die Fehlerkette aus der Enterprise-Incident-History:
   `maximum context length -> 429 -> no available models`).

**Merksatz:** proaktiver und reaktiver Pfad hängen an derselben Zahl. Fehlt
sie, entfällt nicht nur die Anzeige — es faellt auch der einzige
Selbstheilungsweg weg. "Dreadnought compactet selten" ist nicht robuster,
sondern warnungsloser: Fenster wachsen still bis zum harten Abbruch.

## Strategie-Konfiguration (model-proxy.yaml)

`heavy-model` ("Dreadnought"), Fallback-Reihenfolge:
| Modell | Provider | context |
|---|---|---|
| big-pickle (default, Prio 1) | zen-proxy | 200 000 |
| nvidia/nemotron-3-ultra-550b-a55b (Prio 2) | nvidia-direct | 131 072 |
| nvidia/nemotron-3-super-120b-a12b (Prio 3) | nvidia-direct | 131 072 |

Strategie-weite Garantie: `min(...) = 131072`.

## Bewegte Optionen (Entscheidung OFFEN — Praetor/Enterprise)

### Option A: Config-Fix (empfohlen als Basis)
`limit: {context: 131072}` in die Meta-Model-Eintrage der generierten
Ship-Configs injecten (Config-Generierung in starfleetctl).
- Repariert zugleich: Anzeige, Auto-Compaction, Overflow-Selbstheilung.
- **131072 statt 200000**: mit 200000 waere der Fallback auf Nemotron
  heimtueckisch — eine Compaction-Runde laeuft durch (Guard rechnet mit
  200k und sagt "passt"), der erneute Send bricht bei 131k hart ab
  ("Post-compaction provider attempt cannot recover another overflow").
  131072 ist fuer ALLE Mitglieder sicher.

### Option B: Plugin-Reaktionspfad (Zusaetz-Fallback, ggf. ohne Option A)
opencode-Plugin kann `client.session.summarize({sessionID, providerID,
modelID})` direkt aufrufen — das ist der TUI-`/compact`-Pfad, der
**nicht** ueber compactIfNeeded/compactAfterOverflow laeuft und damit den
Guard umgeht. Belege:
- HTTP-Route: `POST /api/session/:sessionID/compact` -> `session.summarize`
- SDK: `client.session.summarize(...)`; unser `starfleet-dispatch.ts`-Plugin
  hat den Client bereits (nutzt schon promptAsync/status/app.log) und
  bereits einen LOG-MONITOR, der opencode.log auf Error-Patterns prueft.
- Trigger-Moeglichkeiten: (1) Token-Schwelle aus Session-Usage, oder
  (2) Log-Pattern "maximum context length" -> summarize -> naechster Turn
  sauber mit Summary weiter.
- Caveat: Guard-Freiheit von `SessionSummary.summarize` aus ~900 Zeichen
  Bundle-Code abgeleitet (Guard lebt an genau zwei Stellen, beide Auto-Pfad)
  — vor Produktivsetzung einmal live testen.

### Option C: Proxy-Fehlerdurchreichung — SCHEIDET AUS
Die Idee, der model-proxy leite den Upstream-Overflow-Fehler opencode-tauglich
durch, damit opencode reaktiv compactet, funktioniert NICHT: opencode
klassifiziert den Fehler zwar korrekt (`context-overflow`-Regex), ruft dann
aber `compactAfterOverflow` auf, der am `limit <= 0`-Guard abbricht.
Zusaetzlich gibt es keinen Kanal, ueber den der Proxy dem laufenden opencode
ein Limit beibringen koennte (opencode liest Modell-Metadaten aus der
models-map der opencode.json, NICHT aus /v1/models — Standing Lesson).

## Offene Fragen

1. **Welcher Weg?** Option A (Config-Fix, eine Zeile, LaForge-Hoheit) /
   Option B (Plugin, mehr Arbeit, aber Guard-agnostisch) / A+B?
2. Wer setzt um: Enterprise hat den starfleetctl-Source uebernommen
   (Claim m1339, Worktree wt/fix-bugs) — passt der Config-Fix in deren Scope,
   oder separates Topic?
3. Soll die Sidebar-Anzeige fuer Strategien das AKTIVE Mitglied-Fenster
   zeigen (dynamisch) oder das strategie-weite Min?

## Kontext / Verwandtes

- Defiant-Session 2026-10-15; Analyse im Console-Thread mit Praetor.
- Verwandt: Standing Lesson "opencode reads per-model metadata from the
  models map in opencode.json, NOT from /v1/models".
- Modellwechsel Defiant: `heavy-model` in Defiant.opencode.json gesetzt,
  Wirksamkeit braucht Neustart (kein Control-Socket, run-gestartete Session).
