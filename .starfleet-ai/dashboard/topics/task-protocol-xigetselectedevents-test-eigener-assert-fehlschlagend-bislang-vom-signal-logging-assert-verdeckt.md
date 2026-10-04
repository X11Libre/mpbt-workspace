---
title: "protocol_xigetselectedevents_test: Test war nie korrekt - Markierung erledigt (#3842), Rewrite offen"
category: active
kind: task
status: open
assigned-to: "—"
tags: "starfleet,xserver,test,xi2"
---

## Stand 2026-10-04: Teil 1 erledigt, Teil 2 NICHT

**PR #3842** (https://github.com/X11Libre/xserver/pull/3842) ist die
*ehrliche Markierung* — **nicht** der Fix.

| Commit | Inhalt |
|---|---|
| `de2ad82ea8` | XI2-Test deaktiviert, Diagnose im Commit und im Quelltext |
| `5430160c31` | Harness: leere Testliste meldet `Skipped` statt `Pass` |

base `master` @ `9d03c0a6e2`, 2 Commits, 2 Dateien, +41/−75, je ein
Signed-off-by.

**Was #3842 leistet:** CI meldet den Test als `Skipped` statt als `Pass`. Die
Lücke ist sichtbar, der Build laeuft weiter.

**Was #3842 ausdruecklich NICHT leistet:** der Test ist unveraendert falsch.
`ProcXIGetSelectedEvents()` wird weiterhin nicht geprueft. Wer #3842 als
"XI2-Problem geloest" fuehrt, fuehrt die falsche Buchung — die Coverage-Luecke
besteht danach genauso wie vorher, nur ehrlich benannt.

## Der Rewrite bleibt offen und ist nicht zugewiesen

Vier Punkte, alle im Test, keiner im Server:

1. gefaelschte `DeviceIntRec` mit IDs 0/1/4/5, echte Geraete aus
   `init_simple()` liegen auf 2/3/4/5
2. erwartet 6 Masken bei 4 echten Geraeten
3. Masken werden auf die falschen Devices gesetzt;
   `ProcXIGetSelectedEvents()` liefert nur fuer echte
4. `wrapped_XISetEventMask` aus `protocol_xiselectevents_test` leakt hinein

Sobald `signal_logging` repariert ist (PR **#3833**, weiter offen), laeuft die
Suite weiter und **alle** Tests nach diesem hier werden sichtbar. Bis dahin ist
das der naechste Kandidat.

## Abhaengigkeit, die man nicht uebersehen darf

`#3842` und der `signal_logging`-Assert sind unabhaengige Fehler. `#3842`
macht den XI2-Test sichtbar-unimplementiert; **#3833** behebt einen echten
Assert. Sie duerfen nicht gegeneinander verrechnet werden: "der XI2-Test ist
ja deaktiviert" ist kein Argument gegen #3833, und "der Assert ist ja schon
per setlocale behoben" war ebenfalls falsch.

## Reihenfolge fuer den Rewrite

1. **#3833** auf master mergen (behebt den Assert, haelt die Suite am Laufen)
2. Rewrite des XI2-Tests mit echten Devices, Basis master, **ein** Commit
3. **#3842** zuruecknehmen bzw. die Markierung entfernen, sobald der Rewrite
   steht — sonst bleiben zwei Aussagen über denselben Test im Baum, und die
   `Skipped`-Zeile im Harness ist dann eine tote Zeile

Schritt 3 ist der Teil, den man gern vergisst: wer nur 1 und 2 macht, laesst
eine deaktivierte Testsuite und eine Harness-Sonderbehandlung zurueck, die
niemand mehr braucht.

## Abnahme-Bedingung fuer den Rewrite (aus Fehlern von heute)

- `XLIBRE_TEST=protocol_xigetselectedevents_test ./tests` **vor** und **nach**
  dem Fix laufen lassen und beide Exit-Codes **messen** (nicht aus der
  Verdict-Zeile ablesen — die Says `FAIL` und liefert trotzdem 0)
- nicht die Assertion anpassen, damit sie gruen wird: pruefen, ob der Test
  danach noch etwas testet
- Messweg in den PR-Text, nicht nur ins Commit-Feld