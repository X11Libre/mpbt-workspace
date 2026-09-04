Title: "bug: session ship-run mit -- <extra> laesst Schiff sofort crashen + Spawn-Crash ohne klare Fehlerursache (SOP-Doku fehlt)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-04T14:49:37Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/bug-ship-run-extra-arg-und-spawn-crash-ohne-klare-fehlerursache

Diagnose 2026-09-04 (Enterprise):

(1) Bedienungsproblem: Wer 'session ship-run --name X --model <m> -- <extra-arg>' aufruft, haengt das Zusatzargument als separates opencode-Positionsargument an. opencode interpretiert ein einzelnes Positionsargument als PROJEKTVERZEICHNIS, nicht als Zusatznachricht -> sofortiger Abbruch (opencode: Failed to change directory to <workspace>/<extra-arg>). Das Schiff crasht beim Start, und das Board meldet nur irrefuehrend 'ship exited unexpectedly (crash/OOM/model error)' statt der echten Ursache.

(2) Zweites, noch offenes Problem: Auch frisch benannte Schiffe OHNE extra-arg (nur --model + System-Start-prompt) crashen beim Start ueber termctl (background/auto), obwohl die laufenden Schiffe identisch gestartet wurden und weiterlaufen, und ein direktes 'opencode run --model ... <msg>' funktioniert. Root cause noch nicht abschliessend geklaert; Verdacht auf Interaktion des headless --prompt-Starts mit einem bereits laufenden lokalen opencode-Server im Workspace (manueller 'opencode --prompt' im Workspace attachte an den Enterprise-Server statt headless zu laufen). Die Web-GUI kann Schiffe problemlos starten.

Gewuenscht (SOP/Doku + ggf. Code):
- Korrekten Weg dokumentieren, ein Schiff fuer einen Task zu spawnen (welche Argumente, wie der Task uebergeben wird - NICHT als bares Positionsargument nach --).
- Fehlermeldung des Boards/Status soll die echte opencode-Fehlerursache enthalten statt pauschal 'model error'.
- Klaeren, warum neue termctl-Spawns crashen, waehrend die Web-GUI funktioniert; ggf. festhalten, dass neue Schiffe ueber die Web-GUI bzw. via 'run' statt barem --prompt-Start gestartet werden sollen.
