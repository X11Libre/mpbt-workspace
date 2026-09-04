---
Title: "generateOpencodeConfig: gueltigen Default-Model-Fallback setzen (Root Cause Ship-Crash ohne --model)"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "Discovery"
Created-By: "Enterprise"
Created: "2026-09-04T16:49:21Z"
Doc-Ref: "—"
Updated: 2026-09-04
Noted-By: "Enterprise"
---

Folge-Task zum Bug 'bug-ship-run-extra-arg-und-spawn-crash-ohne-klare-fehlerursache'. Der eigentliche Root Cause war noch offen: Spawn OHNE explizites --model (frueher Web-GUI, generell) crashte, weil der Default-Model-Fallback in generateOpencodeConfig keine gueltige Model-ID setzte. Workaround aktiv (Web-Pflichtfeld, CLI ohne --model nicht empfohlen).

## Fix (Discovery, 2026-09-04, abgeschlossen)

1. generateOpencodeConfig bekommt jetzt einen model-Parameter; falls leer, wird nvidia/nemotron-3-ultra-550b-a55b (Nemotron Ultra) als Default gesetzt.
2. Default wird in die per-ship Config geschrieben (model: nvidia/nemotron-3-ultra-550b-a55b).
3. CLI-Spawn OHNE --model funktioniert nun: TestShipNoModel startet ohne Crash, Board zeigt 'working'.
4. Web-UI erzwingt weiterhin die Model-Auswahl UI-seitig (Backend wuerde Default akzeptieren).
5. run_cmd.go (CLI terminal) uebergibt das Model fuer Konsistenz.

Verifikation: TestShipNoModel laeuft ohne Crash; Board 'working'; Config enthaelt Default-Model; alle Tests gruen.

Damit sind alle Fixes des Bug-Tasks umgesetzt: (1) Web-Model-Pflichtfeld (UI+Backend 400), (2) CLI-Extra-Args blockiert, (3) bessere Crash-Fehlermeldung (verweist auf Log), (4) Question-Permission 'deny' (String), (5) Default-Model-Fallback in generateOpencodeConfig. Bug-Task schliessbar.