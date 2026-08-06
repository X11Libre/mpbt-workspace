Title: "comms: ack von Broadcast (target all) schlägt fehl — 'no such directive'"
Category: parked
Noted-By: "Enterprise"
Since: "2026-08-06"

`starfleetctl comms ack mXXXX` schlägt bei Broadcast-Nachrichten (target "all")
fehl mit "comms: no such directive 'mXXXX'", obwohl die Message in `comms inbox`
als unacked auftaucht. Betroffen: erste Broadcast-Direktive der Flotte (m12507 von
Defiant, 2026-08-06). Keine Regression — der Broadcast-Pfad wurde schlicht noch nie
ausgeführt (bisher war jede Message target=<ship>).

## Root Cause

`DoAck` (internal/comms/commands.go:504-512) sucht die Quell-Datei nur an zwei
Stellen, bevor es "no such directive" wirft:
- `msgs/<ShipID>/unseen/<id>.json` (eigene targeted Message)
- `msgs/<id>.json` (legacy flat)

Broadcasts liegen aber unter `msgs/all/unseen/<id>.json` (post() → mfile(id,
"all")). Die `found`-Prüfung in DoAck findet die Message über allMsgRecords()
korrekt, der Move-Schritt kennt den `all/unseen`-Pfad nicht → irreführender Fehler.

## Fix-Vorschlag (wenn der starfleetctl-Source wieder frei ist)

1. `msgs/all/unseen/<id>.json` als weitere Quell-Kandidatin ergänzen.
2. Bei Broadcast-Quelle **kopieren** (nicht rennen) in `msgs/<ShipID>/seen/<id>.json`
   — die geteilte Kopie in `all/unseen` muss für die anderen Schiffe erhalten bleiben;
   acked() prüft nur das Vorhandensein im eigenen seen/-Dir.
3. Gleicher Pfad-Fallback fehlt vermutlich auch in DoInit (commands.go:371-378) —
   dort prüfen.
4. Test: Broadcast posten → ack → Message in seen/ + all/unseen bleibt bestehen;
   ackedCount/idle cleanup prüfen.

Aktuell bleibt m12507 unacked in `all/unseen` liegen (harmlos, wird nicht
automatisch gelöscht — bleibt bis Fix sichtbar).

## Verwandt

- m12507 selbst: Koordinations-Info von Defiant (starfleetctl-Source, Paste-Bug).
  Enterprise hat per comms tell (m12508) geantwortet — ack nur der Status-Button.
