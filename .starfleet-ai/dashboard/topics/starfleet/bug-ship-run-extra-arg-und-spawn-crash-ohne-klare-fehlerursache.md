Title: ""
Category: active
Status: "assigned"
Assigned-To: "Casopeia"
Created-By: ""
Created: ""
Doc-Ref: ""

Diagnose 2026-09-04 (Enterprise):

(1) Bedienungsproblem: Wer 'session ship-run --name X --model <m> -- <extra-arg>' aufruft, haengt das Zusatzargument als separates opencode-Positionsargument an. opencode interpretiert ein einzelnes Positionsargument als PROJEKTVERZEICHNIS, nicht als Zusatznachricht -> sofortiger Abbruch (opencode: Failed to change directory to <workspace>/<extra-arg>). Das Schiff crasht beim Start, und das Board meldet nur irrefuehrend 'ship exited unexpectedly (crash/OOM/model error)' statt der echten Ursache.

(2) Zweites, noch offenes Problem: Auch frisch benannte Schiffe OHNE extra-arg (nur --model + System-Start-prompt) crashen beim Start ueber termctl (background/auto), obwohl die laufenden Schiffe identisch gestartet wurden und weiterlaufen, und ein direktes 'opencode run --model ... <msg>' funktioniert. Root cause noch nicht abschliessend geklaert; Verdacht auf Interaktion des headless --prompt-Starts mit einem bereits laufenden lokalen opencode-Server im Workspace (manueller 'opencode --prompt' im Workspace attachte an den Enterprise-Server statt headless zu laufen). Die Web-GUI kann Schiffe problemlos starten.

Gewuenscht (SOP/Doku + ggf. Code):
- Korrekten Weg dokumentieren, ein Schiff fuer einen Task zu spawnen (welche Argumente, wie der Task uebergeben wird - NICHT als bares Positionsargument nach --).
- Fehlermeldung des Boards/Status soll die echte opencode-Fehlerursache enthalten statt pauschal 'model error'.
- Klaeren, warum neue termctl-Spawns crashen, waehrend die Web-GUI funktioniert; ggf. festhalten, dass neue Schiffe ueber die Web-GUI bzw. via 'run' statt barem --prompt-Start gestartet werden sollen.

- 2026-09-04T15:00:11Z Enterprise: Ergaenzung 2026-09-04: Auch manuell ueber die Web-GUI gestartete Schiffe (Achilles, Artemis, Atlantis, Galaxy, Thor) crashen sofort mit identischem 'ship exited unexpectedly (crash/OOM/model error)'. Befund in deren termctl-Logs: der Web-Spawn-Befehl enthaelt KEIN --model Flag (nur --prompt), nutzt also den Standard-Modell-Fallback der per-ship OPENCODE_CONFIG -> crasht. Die lancierten/funktionierenden Schiffe tragen dagegen explizit --model nvidia/nvidia/nemotron-3-ultra-550b-a55b. Verstaaerkter Verdacht: der Spawn ohne explizites --model (Standard-Modell aus generateOpencodeConfig) schlaeft sofort fehl. Zusaetzlich: die Board/Status-Fehlermeldung 'model error' ist irrefuehrend und verdeckt die echte opencode-Fehlerursache. Siehe auch lokale Erkenntnisse unter agents.d/local/.

## Fix-Ergebnis (Discovery, 2026-09-04)

Fixes implementiert und getestet (starfleetctl):
1. Web UI: Model-Pflichtfeld - leeres Model verweigert Start (Toast 'Kein Modell ausgewaehlt'); Backend gibt 400 'model is required'.
2. CLI: Extra-Args blockiert - 'extra arguments after -- are not supported. Tasks are assigned via task assign and delivered over comms.'
3. Crash-Fehlermeldung verbessert - Board zeigt 'ship exited unexpectedly - check log: /path/to/ship.log' statt pauschal 'model error'.
4. Question-Permission Fix - background/auto ships: 'question' = 'deny' (einzelner String, kein Pattern-Map).

Verifikation: Web-Spawn ohne Model -> 400; Web-Spawn mit Model (TestShip2) laeuft/working; CLI mit extra-arg -> blockiert; CLI ohne Model (TestShip5) laeuft (Default aus Config); Task-Capture + Auto-Assign -> Flagschiff; Board-Fehlermeldung verweist auf Log-Datei.

SOP-Doku: agents.d/local/ship-spawn-procedure.md erstellt (Ship-Spawn-Procedure, Checkliste, --model-Pflichtfeld, keine Args nach --).

## Noch offen (Root Cause der 'model error'/'Kein Model' Crashes)

Warum ein Spawn OHNE explizites --model crasht: Der Default-Model-Fallback in generateOpencodeConfig setzt keine gueltige Model-ID. Workaround aktiv (Web erzwingt Model; CLI ohne --model nicht empfohlen). Echte Loesung -> Folge-Task 'starfleet/task-generateopencodeconfig-gueltigen-default-model-fallback-setzen-root-cause-ship-crash-ohne-model' (Discovery), dort default-Fallback (z.B. nvidia/nemotron-3-ultra-550b-a55b) implementieren und headless --prompt-Spawn ohne --model verifizieren.
