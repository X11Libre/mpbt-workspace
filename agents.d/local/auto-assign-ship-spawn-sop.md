# SOP: Auto-Assign und Automatisches Ship-Spawn on Demand

Gilt für: **Flagschiff (Enterprise)** — Steuerung der Task-Delegation und Worker-Ship-Lifecycle.

## 1. Auto-Assign Verhalten

Wenn ein Task mit `--assign auto` (oder Web-GUI "Ship: auto") erfasst wird:

1. Task wird an **Flagschiff (Enterprise)** delegiert (`created-by: <Console>`, `assigned-to: Enterprise`)
2. Flagschiff prüft Board auf **freie Worker** (Status `idle`, nicht `stale`)
3. Falls freier Worker existiert → Task per `task assign <slug> <worker>` zuweisen
4. Falls **kein** freier Worker → **Auto-Spawn** eines neuen Worker-Ships

## 2. Auto-Spawn Regeln

**Wann spawnen:**
- Kein freier Worker auf dem Board (alle `working` oder `stale`)
- Task hat Dringlichkeit (optional: `--priority` in Zukunft)

**Wie spawnen:**
```bash
# Flagschiff führt aus (oder via Comms an sich selbst):
starfleetctl session ship-run --name <auto-assigned> --model nvidia/nemotron-3-ultra-550b-a55b
# dann:
starfleetctl task assign <slug> <new-ship>
```

**Default-Modell für Auto-Spawns:**
- `nvidia/nemotron-3-ultra-550b-a55b` (Nemotron Ultra) — Standard
- `nvidia/nemotron-3-nano-30b-a3b` (Nemotron Nano) — für leichte Tasks (wenn im Task spezifiziert)

**WICHTIG:** Keine Args nach `--` übergeben! Tasks kommen über Comms, nicht als Positionsargumente.

## 3. Task-Delegation via Comms

Flagschiff sendet an Worker:
```bash
starfleetctl comms tell <worker> "Task: <slug> — <Titel>. Details im Dashboard. Bitte bearbeiten und Ergebnis via comms tell Enterprise zurückmelden."
```

Worker:
1. `comms ack <msg-id>`
2. Task aus Dashboard lesen (`starfleetctl dashboard topic show <slug>`)
3. Arbeit ausführen
4. `starfleetctl comms tell Enterprise "Task <slug> erledigt: <Zusammenfassung>"`
5. `starfleetctl task update <slug> --status done` (optional, Flagschiff macht das auch)
6. **`starfleetctl report submit --title "Task <slug> abgeschlossen" --body "<Zusammenfassung>" --taskref <slug>`** — Report einstellen

## 4. Technische Hintergründe

**Warum Comms, nicht Args?**
- opencode `--prompt` interpretiert einzelnes Positionsargument als **Projektverzeichnis** → Crash (`Failed to change directory`)
- Comms (starfleet-dispatch Plugin) ist **einziger** Weg, Tasks an Schiffe zu übergeben
- Schiffe pollen Inbox automatisch (Plugin), keine manuelle Prüfung nötig

**Board-Fehlermeldung:**
- Früher: `ship exited unexpectedly (crash/OOM/model error)` — irreführend
- Jetzt: `ship exited unexpectedly — check log: /path/to/ship.log` — verweist auf echte Ursache

**Default-Model-Fallback (seit Fix):**
- `generateOpencodeConfig` setzt `"model": "nvidia/nemotron-3-ultra-550b-a55b"` wenn keines angegeben
- CLI `session ship-run --name X` ohne `--model` funktioniert jetzt
- Web-GUI erzwingt Model-Auswahl (Pflichtfeld) für Explizitheit

## 5. Checkliste für Flagschiff (Enterprise)

Bei Auto-Assign Task:
- [ ] Board prüfen: `starfleetctl board` → freie Worker (`idle`, nicht `stale`)?
- [ ] Falls ja: `starfleetctl task assign <slug> <worker>` + Comms tell Worker
- [ ] Falls nein: `starfleetctl session ship-run --model nvidia/nemotron-3-ultra-550b-a55b` → Name notieren → `task assign <slug> <new-ship>` → Comms tell new ship
- [ ] Task-Status im Dashboard auf `in-progress` setzen
- [ ] Bei Completion: Task auf `done`, Worker auf `idle` (via Comms status)
- [ ] **Nach Erledigung: `starfleetctl report submit --title "Task <slug> abgeschlossen" --body "<Zusammenfassung>" --taskref <slug>` + Comms an McKinley**

## 6. Web-GUI Workflow (für Praetor/Console)

1. **Tasks** → "Neue Aufgabe" → Titel/Beschreibung
2. **Ship:** `auto` (oder leer) → "Erfassen" → delegiert an Flagschiff
3. **Fleet** → "Neues Schiff" → **Modell wählen** (Pflichtfeld!) → "Starten"
4. Flagschiff delegiert via Comms automatisch

---
*Workspace-SOP (nicht starfleet-instructions). Erstellt im Rahmen von Task `task-workspace-sop-erweitern-auto-assign-und-automatisches-ship-spawn-on-demand`.*