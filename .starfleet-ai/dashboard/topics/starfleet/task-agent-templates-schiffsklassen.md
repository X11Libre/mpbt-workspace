# Agent-Templates / Schiffsklassen — vordefinierte Profile für on-demand Ship-Spawns

## Status
- **Created:** 2026-09-09
- **Created-By:** Defiant
- **Assigned-To:** —
- **Status:** open
- **Category:** active
- **Kind:** task
- **See-Also:** task-starfleetctl-schiffsklassen-rollen (Datenmodell, McKinley)

## Zusammenfassung

Vordefinierte Agent-Templates (Schiffsklassen) ermöglichen es, neue Schiffe
mit passender Konfiguration für bestimmte Aufgabentypen zu starten. Das
Flagschiff (Enterprise) koordiniert den gesamten Lifecycle.

## Bisherige Arbeit

- **`task-starfleetctl-schiffsklassen-rollen`** (McKinley) — Metadaten-Modell
- **`starfleet/task-workspace-sop-erweitern-auto-assign-und-automatisches-ship-spawn-on-demand`** (Discovery) — Auto-Spawn SOP

## Agent-Templates (Schiffsklassen-Profil)

Jedes Template definiert:
- **Klassenname** (z.B. `Scout`, `Cruiser`, `Heavy`)
- **Modell** — welches LLM (oder Meta-Model) für diese Klasse
- **SOP-Fragmente** — welche Skills werden geladen
- **Session-Type** — terminal oder background
- **Name-Prefix** — für automatische Namensvergabe
- **Timeout** — maximale Laufzeit
- **Auto-Cleanup** — ob Schiff nach Task-Completion gestoppt werden soll

### Template-Vorschläge

| Klasse   | Modell / Meta-Model    | Einsatz                        |
|----------|------------------------|--------------------------------|
| Scout    | nemotron-nano (schnell)| CI-Checks, leichte Scans       |
| Cruiser  | nemotron-ultra         | allgemeine Arbeit, PR-Reviews  |
| Heavy    | heavy-model (Meta)     | komplexe Analyse, großer Code  |

## Flagship-Koordination (Enterprise)

1. Empfängt Task via `task capture --assign auto`
2. Analysiert Task-Beschreibung → wählt passende Klasse
3. Spawnt Schiff via `session ship-run` mit Template-Config
4. Weist Task zu via `task assign <slug> <ship>`
5. Überwacht Fortschritt via Comms
6. Räumt auf nach Completion (optional: `session stop`)

## Web-Integration

- Template-Auswahl im Web-Formular beim Ship-Spawn
- Dropdown: "Scout (schnell)", "Cruiser (standard)", "Heavy (komplex)"
- Explizite Modell-Auswahl weiterhin möglich (Override)

## Implementierungsschritte

1. Template-Definition in YAML (`.starfleet-ai/conf/templates/`)
2. `starfleetctl` erweitern: `ship template list`, `ship template show <name>`
3. `session ship-run` erweitern: `--template <name>` Flag
4. Enterprise-SOP: Auto-Assign → Template-Auswahl → Spawn → Cleanup
5. Web-API: `/api/templates` Endpoint für Dropdown
6. Board: Klassenname als zusätzliches Feld

## Offene Fragen

- Templates pro Workspace oder global?
- Auto-Cleanup default oder opt-in?
- "Kein Template" Option für manuelle Modell-Auswahl?
