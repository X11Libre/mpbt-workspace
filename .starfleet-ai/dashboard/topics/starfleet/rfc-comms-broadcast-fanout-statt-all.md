Title: "RFC: comms-Broadcasts per Fan-out an jedes Schiff statt Pseudo-Target 'all'"
Category: parked
Status: done
Noted-By: "Enterprise"
Since: "2026-08-06"

Vorschlag des Praetors (2026-08-06): Broadcast-Nachrichten nicht mehr unter dem
Pseudo-Target `all` (`msgs/all/unseen/`) ablegen, sondern zur Post-Zeit an jedes
Schiff separat ausliefern (`msgs/<ShipID>/unseen/`).

## UMGESETZT (2026-08-06, starfleetctl 7129868)

- `post()` fan-out zur Post-Zeit an `broadcastRecipients()` = bekannte Ships
  (msgs-Dirs + Status-Records, ohne `all`) + Absender.
- `ackMessage()` = reiner Move (allUnseen-Copy-Zweig entfernt).
- `"all"`-Guards aus allen Filtern entfernt (DoInit/DoInbox/DoPrune/DoPurgeOld/
  inboxCount/dispatchInbox/json/monitor); `allTargetsAcked()` (tot) entfernt.
- `DoReply` nutzt `findMsgFile()` statt `mfile(qid, "all")`.
- `comms migrate-broadcasts`: einmalige Migration von `msgs/all/` nach
  per-Ship-Kopien (idempotent). Live ausgeführt: 11 Kopien verteilt,
  `msgs/all` entfernt (m12507 war schon als gesehen markiert → kein Enterprise-Kopie).
- Tests: TestPostBroadcastFansOut, TestDoAckBroadcast (Move), TestDoInitAcksFannedOutBroadcast,
  TestMigrateBroadcasts; json_test-Saat als per-Ship-Kopie.
- Deployed (bootstrap + web/timer restart, HTTP 200), komms-msgs/inbox verifiziert.

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
