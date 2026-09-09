# Agent-Templates / Schiffsklassen — vordefinierte Profile für on-demand Ship-Spawns

## Status
- **Created:** 2026-09-09
- **Created-By:** Defiant
- **Assigned-To:** —
- **Status:** open
- **Category:** active
- **Kind:** task

## Zusammenfassung

Vordefinierte Agent-Templates (Schiffsklassen) ermöglichen es, neue Schiffe
mit passender Konfiguration für bestimmte Aufgabentypen zu starten. Das
Flagschiff (Enterprise) koordiniert den gesamten Lifecycle: Template-Auswahl,
Spawn, Überwachung, Aufräumen.

## Bisherige Arbeit

Bereits existierende Topics:
- `task-starfleetctl-schiffsklassen-rollen` — Metadaten/Board-Anzeige
- `starfleet/task-workspace-sop-erweitern-auto-assign-und-automatisches-ship-spawn-on-demand` — Auto-Spawn SOP

Dieser Topic konsolidiert und erweitert beides.

## Anforderungen

### 1. Agent-Templates (Schiffsklassen-Profil)

Jedes Template definiert:
- **Klassenname** (z.B. `Scout`, `Cruiser`, `Heavy`)
- **Modell** — welches LLM für diese Klasse verwendet wird
  - `Scout`: nemotron-nano (schnell, billig) — leichte Scans, CI-Checks
  - `Cruiser`: nemotron-ultra (standard) — allgemeine Arbeit
  - `Heavy`: big-pickle / andere schwere Modelle — komplexe Analyse, Code-Review
- **SOP-Fragmente** — welche Skills werden geladen (immer-geladen vs. on-demand)
- **Session-Type** — terminal oder background
- **Name-Prefix** — für automatische Namensvergabe (z.B. `Scout-7`, `Cruiser-3`)
- **Timeout** — maximale Laufzeit
- **Auto-Cleanup** — ob Schiff nach Task-Completion gestoppt werden soll

### 2. Flagship-Koordination (Enterprise)

Enterprise als koordinierendes Flagschiff:
1. Empfängt Task via `task capture --assign auto`
2. Analysiert Task-Beschreibung → wählt passendes Template
3. Spawnt Schiff via `session ship-run` mit Template-Config
4. Weist Task zu via `task assign <slug> <ship>`
5. Überwacht Fortschritt via Comms
6. Räumt auf nach Completion (optional: `session stop`)

### 3. Web-Integration

- Template-Auswahl im Web-Formular beim Ship-Spawn
- Dropdown: "Scout (schnell)", "Cruiser (standard)", "Heavy (komplex)"
- Explizite Modell-Auswahl weiterhin möglich (Override)

### 4. Implementierungsschritte

1. Template-Definition in YAML/JSON (unter `.starfleet-ai/conf/` oder `var/`)
2. `starfleetctl` erweitern: `ship template list`, `ship template show <name>`
3. `session ship-run` erweitern: `--template <name>` Flag
4. Enterprise-SOP: Auto-Assign → Template-Auswahl → Spawn → Cleanup
5. Web-API: `/api/templates` Endpoint für Dropdown
6. Board: Klassenname als zusätzliches Feld

## Offene Fragen

- Sollen Templates pro Workspace konfigurierbar sein oder global?
- Soll Auto-Cleanup default sein oder opt-in?
- Braucht es eine "kein Template" Option für manuelle Modell-Auswahl?
