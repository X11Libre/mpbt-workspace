Title: "generateOpencodeConfig: gueltigen Default-Model-Fallback setzen (Root Cause Ship-Crash ohne --model)"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "Discovery"
Created-By: "Enterprise"
Created: "2026-09-04T16:49:21Z"
Doc-Ref: "—"

Folge-Task zum Bug 'bug-ship-run-extra-arg-und-spawn-crash-ohne-klare-fehlerursache'. Der eigentliche Root Cause ist noch offen: Spawn OHNE explizites --model (frueher Web-GUI, und generell) crasht, weil der Default-Model-Fallback in generateOpencodeConfig keine gueltige Model-ID setzt. Workaround aktiv (Web erzwingt Model-Pflichtfeld, CLI ohne --model nicht empfohlen). Echte Loesung: generateOpencodeConfig soll einen gueltigen Fallback setzen (z.B. nvidia/nemotron-3-ultra-550b-a55b), verifizieren, dass headless --prompt-Spawn ohne --model damit laeuft. Board-Fehlermeldung zeigt nun korrekt 'ship exited unexpectedly - check log: <path>'.
