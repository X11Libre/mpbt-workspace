# Ship Spawn Procedure — korrekter Weg, Schiffe mit Aufgaben zu starten

## Problem (BEHOBEN)

`session ship-run --name X --model <m> -- <extra-arg>` crash das Schiff sofort, weil opencode ein einzelnes Positionsargument nach `--prompt` als **Projektverzeichnis** interpretiert (Fehler: `Failed to change directory to <workspace>/<extra-arg>`). Das Board meldet dann irreführend nur `ship exited unexpectedly (crash/OOM/model error)`.

**Früher:** Auch Web-GUI-Spawns ohne explizites `--model` crashen, weil der Standard-Modell-Fallback aus der per-ship OPENCODE_CONFIG fehlschlug.
**Jetzt (Fix):** `generateOpencodeConfig` setzt Default `nvidia/nemotron-3-ultra-550b-a55b` (Nemotron Ultra) → CLI `session ship-run --name X` OHNE `--model` funktioniert. Web-GUI erzwingt Model-Auswahl (Pflichtfeld) für Klarheit.

## Korrekte Vorgehensweise

**Schiffe bekommen Aufgaben NICHT über bare Argumente nach `--`**, sondern über:

1. **Task erfassen** (`starfleetctl task capture` oder Web-GUI "Neue Aufgabe")
2. **Task zuweisen** (`starfleetctl task assign <slug> <ship>` oder `--assign` bei capture)
   - Das Flagschiff (Enterprise) delegiert an freie Worker
   - Auto-Assign (`__auto__`) routet immer zum Flagschiff
3. **Das Schiff pollt** die Comms-Inbox (automatisch via Plugin) und führt die Direktive aus
4. **Ergebnis via Comms zurückmelden** (`starfleetctl comms tell <sender> <reply>`)

## Beispiele

### Web-GUI (Neue Aufgabe + Schiff spawnen)
1. Tab "Tasks" → "Neue Aufgabe" → Titel/Beschreibung eingeben
2. Ship: leer lassen oder `auto` → "Erfassen" (Task wird ans Flagschiff delegiert)
3. Tab "Fleet" → "Neues Schiff" → **Modell wählen** (Pflichtfeld!) → "Starten"
4. Flagschiff delegiert Task an das neue Schiff via Comms

### CLI
```bash
# Task erfassen und direkt an freies Schiff (via Flagschiff) delegieren
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

## Empfohlene Standard-Modelle

Für neue Schiffe (wenn im Task nicht anders angegeben):
- `nvidia/nemotron-3-ultra-550b-a55b` (Nemotron Ultra) — Flagschiff-Standard
- `nvidia/nemotron-3-nano-30b-a3b` (Nemotron Nano, schnell) — für leichte Tasks

## Technische Hintergründe (Token-sparend)

- opencode `--prompt` erwartet **keine** weiteren Positionsargumente. Alles nach dem Prompt-String wird als Projektpfad gewertet.
- Die Comms-Schicht (starfleet-dispatch Plugin) ist der **einzige** Weg, um Tasks an Schiffe zu übergeben.
- Web-GUI-Spawns ohne Modell nutzen den Fallback aus `generateOpencodeConfig`, der keine gültige Default-Modell-ID setzt → sofortiger Crash.
- Die Board-Fehlermeldung `model error` verdeckt die echte opencode-Fehlerursache (siehe Bug-Task für Fix).

## Checkliste für Schiff-Spawns

- [ ] `--model` explizit angeben (CLI) / im Dropdown wählen (Web-GUI)
- [ ] Keine Args nach `--` übergeben
- [ ] Task separat über Dashboard/Comms zuweisen
- [ ] Bei Web-GUI: Modell-Pflichtfeld beachten (UI sollte das erzwingen)