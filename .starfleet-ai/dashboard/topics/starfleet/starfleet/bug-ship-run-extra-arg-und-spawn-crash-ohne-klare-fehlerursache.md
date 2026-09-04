Title: "bug: session ship-run -- <extra-arg> lässt das Schiff sofort crashen (fehlende SOP-Doku)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-04T14:48:40Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/starfleet/bug-ship-run-extra-arg-und-spawn-crash-ohne-klare-fehlerursache

BDIAGNOSE 2026-09-04 (Enterprise):
(1) Bedienungsproblem: 'starfleetctl session ship-run --name X --model <m> -- <extra-arg>' hängt das Zusatzargument als separates opencode-Positionsargument an. opencode interpretiert ein einzelnes Positionsargument als PROJEKTVERZEICHNIS, nicht als Zusatznachricht -> sofortiger Abbruch: 'Error: Failed to change directory to <workspace>/<extra-arg>'. Das Schiff crasht beim Start, und das Board meldet nur irreführend 'ship exited unexpectedly (crash/OOM/model error)' statt der echten Ursache.

(2) Zweites, noch offenes Problem: Auch frisch benannte Schiffe OHNE extra-arg (nur --model + System-) crashen beim Start über termctl (background/auto), obwohl die laufenden Schiffe identisch gestartet wurden und weiterlaufen und ein direktes 'opencode run --model ... <msg>' funktioniert. Root cause noch nicht abschließend geklärt; Verdacht auf Interaktion des headless -Starts mit einem bereits laufenden lokalen opencode-Server im Workspace (mein manueller 'opencode --prompt' im Workspace attachte an den Enterprise-Server statt headless zu laufen). Die Web-GUI kann Schiffe problemlos starten.

GEWÜNSCHT (für SOP/Doku + ggf. Code):
- Korrekten Weg dokumentieren, ein Schiff für einen Task zu spawnen (welche Argumente; wie der Task übergeben wird — nicht via barem Positionsargument nach --).
- Fehlermeldung des Boards/Status soll die echte opencode-Fehlerursache enthalten statt pauschal 'model error'.
- Klären, warum neue termctl-Spawns crashen, während die Web-GUI funktioniert; falls nötig festhalten, dass neue Schiffe über die Web-GUI bzw. via 'run' statt barem --prompt-Start gestartet werden sollen.
