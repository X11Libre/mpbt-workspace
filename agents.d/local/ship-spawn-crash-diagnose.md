# Ship-Spawn-Symptome (2026-09-04, Enterprise)

Diagnose für das sofortige Crash-Problem neuer Schiffe ("ship exited
unexpectedly (crash/OOM/model error)"). Ergebnisse in Bug-Task
`starfleet/bug-ship-run-extra-arg-und-spawn-crash-ohne-klare-fehlerursache`
festgehalten.

## Befund 1 — `-- <extra-arg>` wird Projektverzeichnis
`starfleetctl session ship-run --name X --model <m> -- <extra>` hängt das
Zusatzargument als separates opencode-Positionsargument an. opencode
interpretiert ein einzelnes Positionsargument als **Projektverzeichnis**
(Fehler: `Failed to change directory to <workspace>/<extra>`), nicht als
Nachricht → Schiff crasht sofort. Ein extra-Arg nach `--` ist also KEIN Weg,
dem Schiff einen Auftrag zu übergeben.

## Befund 2 — Spawn ohne `--model` crasht (Standard-Modell-Fallback)
Auch frisch benannte Schiffe crashen beim termctl-Start:
- CLI mit `--model nvidia/nvidia/nemotron-3-ultra-550b-a55b` → crasht trotzdem.
- Web-GUI-Spawns (Achilles, Artemis, …) haben **kein `--model`** im Befehl
  (nur `--prompt`), nutzen das Standard-Modell der per-ship OPENCODE_CONFIG →
  crashen ebenfalls.
- Die bestehenden, funktionierenden Schiffe liefen mit explizitem `--model`
  und laufen weiter; ein direktes `opencode run --model … <msg>` funktioniert.

## Befund 3 — irreführende Fehlermeldung
Board/Status meldet nur `crash/OOM/model error`, nie die echte opencode-
Fehlerursache. Erschwert jede Diagnose.

## Offene Frage / Root cause
Warum crasht der termctl-Spawn sogar mit explizitem `--model`, während Web-GUI
früher funktionierte? Verdacht: headless `--prompt`-Start interagiert mit dem
bereits laufenden lokalen opencode-Server im Workspace (manuelles
`opencode --prompt` im Workspace attachte an den Enterprise-Server statt
headless zu laufen) und/oder ein Standard-Modell-Fallback in
`generateOpencodeConfig`.
