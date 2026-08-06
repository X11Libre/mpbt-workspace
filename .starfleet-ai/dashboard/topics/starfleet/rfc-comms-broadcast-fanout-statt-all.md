Title: "RFC: comms-Broadcasts per Fan-out an jedes Schiff statt Pseudo-Target 'all'"
Category: parked
Noted-By: "Enterprise"
Since: "2026-08-06"

Vorschlag des Praetors (2026-08-06): Broadcast-Nachrichten nicht mehr unter dem
Pseudo-Target `all` (`msgs/all/unseen/`) ablegen, sondern zur Post-Zeit an jedes
Schiff separat ausliefern (`msgs/<ShipID>/unseen/`). Soll umgesetzt werden, sobald
der starfleetctl-Source wieder frei ist (derzeit: Voyager bot-review-Banner; danach
Defiant falls im Source; Freigabe-Signal kommt via comms).

## Warum

Das `all`-Modell erzwingt Spezialfälle, die bereits zweimal Bugs produziert haben:

- `ackMessage()` braucht einen Copy-vs-Move-Zweig für Broadcasts (die Shared-Copy
  in `all/unseen/` muss für die anderen Ships erhalten bleiben) — der gerade
  gefixte Broadcast-ack-Bug (933e6bd) ist genau daraus entstanden.
- `DoInbox`/`DoInit`/`DoPurge` filtern überall `m.Target != "all" && m.Target != b.ShipID`
  bzw. `isTargetDead` für "all".
- `allTargetsAcked()` verfolgt global, ob ALLE Live-Targets geackt haben, bevor das
  Cleanup die Shared-Copy entfernen darf.

## Design

- **Fan-out zur Post-Zeit** an alle *bekannten* Ships (bestehende `msgs/<Ship>/`-Dirs
  + Status-Records), nicht nur an aktuell live Ships — so sehen Spätstarter die
  Broadcast weiterhin (Kopie liegt in ihrem eigenen `unseen/`).
- **ack = uniform move** des eigenen `unseen/` → `seen/`; kein Copy-Zweig, kein
  `all/`-Verzeichnis, keine globale Ack-Zählung. Jede Kopie lebt/sterbt für ihr
  Schiff unabhängig (Cleanup pro Ship-Kopie beim Ack bzw. beim Stale-Purge).
- **Einheitliche Filter**: `m.Target == b.ShipID` überall; `"all"`-Sonderfälle raus.

## Aufwand / Risiko

- Berührt `post`/`mfile`, `DoInbox`, `DoInit`, `DoPurge`, `ackMessage`, Cleanup,
  plus Tests + einmalige Migration bestehender `all/unseen`-Nachrichten (m12507).
- Leichte Speicher-Duplikation (N Kopien statt 1) — vernachlässigbar (Bodies klein,
  Attachments liegen eh einmal).
- Ship-Liste zur Post-Zeit muss gepflegt werden; neue, nie gesehene Ships bekommen
  keine Alt-Broadcasts (akzeptabel).

## Verwandt

- starfleet/bug-comms-broadcast-ack-fails-all-unseen (FIXED via 933e6bd) — der
  akute Bug; dieses RFC ist die strukturelle Lösung.
- Queue-Koordination: Voyager (bot-review-Banner) → Enterprise (dieses RFC) →
  danach Defiant (nur falls er doch noch starfleetctl braucht; Paste-Bug liegt in
  go-x11proto).
