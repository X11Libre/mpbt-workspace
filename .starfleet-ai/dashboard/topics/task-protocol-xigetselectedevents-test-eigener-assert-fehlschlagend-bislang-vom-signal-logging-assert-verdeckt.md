---
title: "protocol_xigetselectedevents_test: Test war nie korrekt - Fake-Devices statt echter, Fremd-Override leakt"
category: active
kind: task
status: assigned
assigned-to: "Galaxy"
tags: "starfleet,xserver,test,xi2"
---

## Diagnose (Galaxy, 2026-10-04) — der Assert ist das Symptom

Gemeldete Fehlstelle: `test/xi2/protocol-xigetselectedevents.c:95`

```
reply_XIGetSelectedEvents: Assertion `reply.num_masks == test_data.num_masks_expected' failed
```

Gemessene Ursache — vier Punkte, alle im Test, nicht im Server:

1. Der Test benutzt **gefälschte `DeviceIntRec`-Strukturen** mit hartkodierten
   IDs. Die echten IDs aus `init_simple()` sind **vcp=2, vck=3, mouse=4,
   kbd=5** — der Test nimmt 0, 1, 4, 5 …
2. Er erwartet **6 Masken** (`num_devices + 2`), es existieren aber nur **4
   echte Geräte**.
3. Er setzt Masken auf die gefälschten Devices, aber
   `ProcXIGetSelectedEvents()` liefert Masken **nur für echte Devices**
   zurück — der Zähler kann nie stimmen.
4. `wrapped_XISetEventMask` wird nicht korrekt benutzt: der Override aus
   `protocol-xiselectevents_test` **leakt** in diesen Test hinein.

**Konsequenz:** Der Test prüft den XI2-Select-Events-Pfad mit erfundenem
Device-Zustand, während der Serverpfad aus der globalen Device-Liste liest. In
dieser Form kann er nicht bestehen. Galaxy empfiehlt einen Rewrite mit echten
Device-Pointern.

## Warum das auf ALEN Zweigen liegt — nicht nur auf master

Das ist die Folge, die beim Aufgaben nicht sichtbar war:

- Auf `master` bricht `signal_logging_test` ab, also laeuft dieser Test nie.
- Auf 25.0/25.2 meldet der Harness `FAIL` und beendet sich mit 0, also
  laeuft er ebenfalls nie.
- Sobald **beides** behoben ist — Harness-Haertung (`#3834`/`#3835`) **und**
  der `signal_logging`-Assert (`#3833` + Backports) — laeuft der Test auf allen
  vier Zweigen **zum ersten Mal** und schlaegt dort zu.

Er ist also **nicht** ein master-Thema, das man parallel erledigen kann,
sondern eine Bedingung fuer gruenes CI auf allen Zweigen.

## Zwei Wege, und sie sind nicht gleichwertig

| | Inhalt | Wirkung |
|---|---|---|
| **(i)** | Test mit echten Devices neu schreiben | schliesst die IX2-Luecke, teuer |
| **(ii)** | Test als "nicht implementiert" markieren, mit Diagnose im Quelltext | CI ehrlich, Luecke sichtbar, billig |

Nicht richtig waere, den Test so umzuschreiben, dass er *gruen* wird, ohne zu
pruefen, ob er damit ueberhaupt noch etwas testet. Ein Rewrite, der die
Assertion anpasst statt die Ursache, ist derselbe Fehler wie der
urspruengliche Assert: unerfuellbar behauptet, scheinbar gruen.

## Aufteilung, wie entschieden

1. **Galaxy, sofort, klein:** Variante (ii) als **einen** Commit auf master —
   der Test wird explizit als nicht implementiert markiert, mit der Diagnose
   und einem Verweis auf diese Zeilen im Quelltext. Damit ist CI ehrlich und
   der Bau laeuft weiter. Ein Kommentar im Test, kein stilles Weglassen.
2. **Variante (i), eigener Task:** Rewrite mit echten Devices. Gehoert zu
   jemandem mit XI2- und Testharness-Kontext, und **nicht** als Nebenschritt.

Die Langzeitentscheidung (Luecke schliessen oder Luecke als Luecke
markiert lassen) ist eine Abwaegungsfrage des Maintainers und liegt bei
McKinley — die Task hier behaelt beide Wege sichtbar.