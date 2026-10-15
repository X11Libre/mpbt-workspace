Title: "BUG web: 'neueste N' Nachrichten per ID statt Zeit -> nach ID-Reset unsichtbar (m4xxx verdeckt m1xxx)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-15T10:39:03Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: bug-web-recent-msgs-per-id-nach-reset

Gemeldet vom Praetor 2026-10-15: "im webfrontend sehe ich bei dir [Enterprise] keine neuen messages mehr, aber bei anderen schiffen."

## Ursache (gemessen)
Das Web holt pro Schiff nur die neuesten `BUS_MSG_LIMIT=300`:
`/api/msgs?ship=<name>&limit=300` (index.html:1423) -> `ConversationRecentRecordsJSON(ship,300)` -> `ConversationRecentRecords` (records.go). Dieses iteriert `conversationFiles()` und **bricht bei max ab**; `conversationFiles()` sortiert nach **numerischer Nachrichten-ID absteigend** (`parseIDNum`). "Neueste" ist also = hoechste ID, NICHT = spaeteste Zeit.

Der ID-Zaehler wurde zurueckgesetzt: `.seq` = **1330**, aber im Store liegen noch **504 Nachrichten mit m4xxx** (hoechste = m4513, ~41h alt). Folge: die 300 hoechsten IDs sind die ALTEN m4xxx -> das Web zeigt bei Enterprise die alten Statuts, die neuen (m13xx) fallen aus dem Fenster. Nebeneffekt: die ID kollidiert demnaechst wieder (Zaehler laeuft auf m4513 zu).

Messbeleg (limit=20, erste Eintraege):
- Enterprise -> m4513 (age 147538s)  ✗ alt
- Defiant    -> m4500 (age 147917s)  ✗ alt
- Voyager    -> m4512 (age 147654s)  ✗ alt
- McKinley   -> m4482 (age 149029s)  ✗ alt
- NIM        -> m1330 (age 22s)      ✓ neu (Store ohne Pre-Reset-Nachrichten)
Ohne limit ist die Reihenfolge korrekt (Enterprise: m1329 age 1 zuerst) — der Fehler steckt nur im limit/Selektionspfad.

## Ausloeser
`nextID()` (commands.go:24) liest den Zaehler aus `MsgDir/.seq`, das unter dem ephemeren `var/` liegt. Wird `.seq` verloren/zurueckgesetzt waehrend alte `msgs/` erhalten bleiben, laufen neue IDs UNTER die alten.

## Fix-Vorschlag (LaForge)
1. "Neueste N" nach **Epoch/Zeit** statt nach numerischer ID waehlen: in `conversationFiles`/`allMsgRecords` nach `Epoch` (oder einem (epoch,id)-Tupel) sortieren, nicht nach `parseIDNum`. Zentral, da `allMsgRecords` denselben id-Sort nutzt.
2. Robuster Zaehler: `nextID` auf `max(existing id)+1` bzw. `max(.seq, hoechste vorhandene id)+1` klettern lassen, damit ein verlorenes `.seq` keine Rueckwaerts-IDs/Kollisionen erzeugt.
3. Optional: `.seq` nicht-ephemer halten.

Impact: betrifft die Web-Bus-/Conversation-Anzeige flottenweit fuer jedes Schiff, dessen Store Pre-Reset-Nachrichten enthaelt. Kein Datenverlust, aber "neue Nachrichten" werden unsichtbar.
