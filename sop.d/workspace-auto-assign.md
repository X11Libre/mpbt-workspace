---
Title: "Workspace SOP: Auto-Assign und Auto-Spawn von Schiffen"
Category: local
Kind: "sop"
Status: "active"
Created-By: "Scotty"
Created: "2026-09-10T15:00:00Z"
Doc-Ref: "—"
---

# Workspace SOP: Auto-Assign und Auto-Spawn von Schiffen

## Zweck

Dieser SOP definiert das Verhalten des Flagschiffs (Enterprise) bei der automatischen Zuweisung und Erstellung von Arbeiter-Schiffen im Workspace `mpbt-workspace`.

## Auto-Assign Verhalten

Wenn ein Task mit `--assign auto` (oder Web-GUI "Ship: auto") erfasst wird:

1. Task wird an **Flagschiff (Enterprise)** delegiert (`created-by: <Console>`, `assigned-to: Enterprise`)
2. Flagschiff prüft Board auf **freie Worker** (`comms board` → Status `idle`, nicht `stale`)
3. Falls freier Worker existiert → `task assign <slug> <worker>` + Comms tell Worker
4. Falls **kein** freier Worker → **Auto-Spawn** eines neuen Worker-Ships

## Auto-Spawn Regeln

**Wann spawnen:**
- Kein freier Worker auf dem Board (alle `working` oder `stale`)
- Task hat Dringlichkeit (optional: `--priority` in Zukunft)

**Wie spawnen:**
```bash
starfleetctl session ship-run --name <auto-assigned> --model nvidia/nemotron-3-ultra-550b-a55b
starfleetctl task assign <slug> <new-ship>
```

**Default-Modelle für Auto-Spawns:**
- `nvidia/nemotron-3-ultra-550b-a55b` (Nemotron Ultra) — Standard
- `nvidia/nemotron-3-nano-30b-a3b` (Nemotron Nano, schnell) — für leichte Tasks (wenn im Task spezifiziert)

## Korrekte Vorgehensweise & Beispiele

**Schiffe bekommen Aufgaben NICHT über bare Argumente nach `--`, sondern über:**

1. **Task erfassen** (`starfleetctl task capture` oder Web-GUI "Neue Aufgabe")
2. **Task zuweisen** (`task assign <slug> <ship>` oder `--assign` bei capture)
   - Auto-Assign (`__auto__`) routet immer zum Flagschiff
3. **Das Schiff pollt** die Comms-Inbox (automatisch via Plugin) und führt die Direktive aus
4. **Ergebnis via Comms zurückmelden** (`comms tell <sender> <reply>`)

### Web-GUI (Neue Aufgabe + Schiff spawnen)
1. Tab "Tasks" → "Neue Aufgabe" → Titel/Beschreibung
2. Ship: leer lassen oder `auto` → "Erfassen" (Task wird ans Flagschiff delegiert)
3. Tab "Fleet" → "Neues Schiff" → **Modell wählen** (Pflichtfeld!) → "Starten"
4. Flagschiff delegiert Task an das neue Schiff via Comms

### CLI
```bash
# Task erfassen und direkt delegieren (via Flagschiff)
starfleetctl task capture "Titel" --desc "Beschreibung" --assign auto

# Oder: Schiff zuerst starten (MIT --model!), dann Task zuweisen
starfleetctl session ship-run --name Voyager --model nvidia/nemotron-3-ultra-550b-a55b
starfleetctl task assign <slug> Voyager
```

### WICHTIG: Immer --model angeben
```bash
# RICHTIG
starfleetctl session ship-run --name Voyager --model nvidia/nemotron-3-ultra-550b-a55b

# FALSCH (crash!)
starfleetctl session ship-run --name Voyager --model nvidia/nemotron-3-ultra-550b-a55b -- "mach das und das"
```

## Task-Delegation via Comms (Worker-Workflow)

Flagschiff sendet an Worker:
```bash
starfleetctl comms tell <worker> "Task: <slug> — <Titel>. Details im Dashboard. Bitte bearbeiten und Ergebnis via comms tell Enterprise zurückmelden."
```

Worker:
1. `comms ack <msg-id>`
2. Task aus Dashboard lesen (`starfleetctl dashboard topic show <slug>`)
3. Arbeit ausführen
4. `comms tell Enterprise "Task <slug> erledigt: <Zusammenfassung>"`
5. `task update <slug> --status done` (optional, Flagschiff macht das auch)
6. **`starfleetctl report submit --title "Task <slug> abgeschlossen" --body "<Zusammenfassung>" --taskref <slug>`** — Report einstellen

## Checkliste für Flagschiff (Enterprise)

Bei Auto-Assign Task:
- [ ] Board prüfen: `comms board` → freie Worker (`idle`, nicht `stale`)?
- [ ] Falls ja: `task assign <slug> <worker>` + Comms tell Worker
- [ ] Falls nein: `session ship-run --model nvidia/nemotron-3-ultra-550b-a55b` → Name notieren → `task assign <slug> <new-ship>` → Comms tell new ship
- [ ] Task-Status im Dashboard auf `in-progress` setzen
- [ ] Bei Completion: Task auf `done`, Worker auf `idle` (via Comms status)
- [ ] **Nach Erledigung: `report submit --title "Task <slug> abgeschlossen" --body "<Zusammenfassung>" --taskref <slug>` + Comms an McKinley**

## Checkliste für Schiff-Spawns (allgemein)

- [ ] `--model` explizit angeben (CLI) / im Dropdown wählen (Web-GUI)
- [ ] Keine Args nach `--` übergeben
- [ ] Task separat über Dashboard/Comms zuweisen
- [ ] Bei Web-GUI: Modell-Pflichtfeld beachten (UI sollte das erzwingen)

## Token-Spar-Hinweis

Default-Modell Nemotron Ultra (nvidia/nemotron-3-ultra-550b-a55b) ist mächtig aber token-intensiv. Für leichte Tasks (Kontakt-Suche, einfache Code-Änderungen, Status-Abfragen) kann `--model nvidia/nemotron-3-nano-30b-a3b` (Nemotron Nano) im Task angegeben werden, um Quota zu sparen.

## Referenz

Dieser SOP basiert auf den gelernten Lessons aus `local/ship-spawn-and-auto-assign` und der Implementierung in `starfleetctl` (commit f84d312: Auto-Assign routet immer zum Flagschiff).
