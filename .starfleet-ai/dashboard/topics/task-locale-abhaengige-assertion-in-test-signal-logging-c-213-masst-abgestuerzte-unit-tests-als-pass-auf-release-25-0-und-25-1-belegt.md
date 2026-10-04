---
title: "Locale-abhaengige Assertion in test/signal-logging.c:213 masst abgestuerzte Unit-Tests als PASS (auf release/25.0 und 25.1 belegt)"
category: active
kind: task
status: assigned
assigned-to: "Barcley"
tags: "starfleet,xserver,test,locale,backport"
---

## Stand 2026-10-04 (Enterprise): der Assert ist nicht locale-abhaengig

Die Arbeits-Hypothese im Titel ("locale-abhaengig") ist **widerlegt**. Gemessen,
nicht gelesen — 2x2-Matrix am laufenden `test/tests`:

| | `LC_ALL=C` | `LC_ALL=de_DE.utf8` |
|---|---|---|
| vorher (`c94c967612` / `d304231c38`) | FAIL | FAIL |
| nachher (#3831 / #3832) | FAIL | FAIL |

Zwei Gruende, beide gemessen:

1. **Die Locale kommt nie an.** Ein C-Programm startet in der `"C"`-Locale, und
   im Baum wird nirgends `setlocale(LC_ALL, "")` gerufen. Die Umgebungsvariable
   wirkt also ueberhaupt nicht. `grep -rn 'setlocale' test/` findet genau einen
   Treffer.
2. **Der Assert rechnet falsch.** `assert(strcmp(&logmsg[strlen(logmsg) - 3],
   "en\n") == 0)` in `test/signal-logging.c:214` (bzw. 213 vor dem
   Verschieben) prueft die **Abschneidung**, nicht die Locale:
   - `os/log.c:744` `#define LOG_MSG_BUF_SIZE 1024`
   - `os/log.c:775` `len = prepMsgHdr()` → 5 (`"(EE) "`), dann
     `vpnprintf(&buf[5], 1019, ...)` → 1018, also `len = 1023`
   - `os/log.c:765` `writeLog()`: `1024 - 1023 == 1` → `buf[1022] = '\n'`
   - Testfuellung: `char buf[1024]`, 1020 Punkte + `"end"` — `"end"` beginnt bei
     Index 1020 und wird **nie** erreicht.
   - Ergebnis: die letzten drei Bytes sind `"..\n"`, nicht `"en\n"`.
   - Messung am Binary: `rawlen=1045 tslen=20 last4 = 2e 2e 2e 0a`.
     Der Zeitstempel ist via `strftime("[%Y-%m-%d %H:%M:%S] ")` konstant 21
     Zeichen, also selbst keine Laengen-Quelle.

Der Assert ist auf `master`, `release/25.0`, `release/25.1` und `release/25.2`
woertlich identisch, `LOG_MSG_BUF_SIZE` ueberall 1024 — er ist damit auf **allen**
Zweigen unmoeglich zu erfuellen.

## Warum das seit langem unentdeckt blieb (der zweite Teil im Titel)

`./test/tests` beendet sich mit **exit 0**, auch wenn `signal_logging_test`
`FAIL` meldet. `meson test` zeigt deshalb `13/16 xserver / unit ... OK`
(CI-Log, Run 37007870905), waehrend der Assert brennt. Ein gruenes `unit` in CI
ist also **kein** Beweis fuer diesen Test.

## Was daneben erledigt ist

- **PR #3832** (`release/25.1`): ein Commit, 15 Fremd-Commits aus #3827
  zurueckgenommen. Der Branch war rot wegen
  `82da0c6c45 "modesetting: save cursor in master's sprite_priv"`, das
  `IsFloating()` ohne Deklaration aufruft
  (`drmmode_display.c:5250`). Beide Richtungen gemessen: ungepatcht FAILED,
  gepatcht baut und linkt. Commit dazu in m128621.
- **PR #3831** (`release/25.0`): ein Commit, `setlocale()` von
  `logging_format()` nach `signal_logging_test()` verschoben — so wie
  McKinley es verlangt hat. **Hygiene, kein Fix** (siehe Matrix oben).
- release/25.0 ist aktuell **gruen** (Run 37139067064 auf `c94c96761`).

## Offen (Barcley)

1. Fix des Abschneide-Asserts, **master zuerst**, als eigener PR, ein Commit.
   Beide Stellen (die zweite Variante ist die String-Substitution-Zeile
   darunter) und die auf allen Releases vorhandene Zeilennummer beachten.
2. Entscheidung, ob Test-Erwartung oder `writeLog()`-Logik die richtige
   Referenz ist — vor der Wahl messen, nicht danach.
3. `[]` als Formatbezeichner in Benchmarks ist verboten — die Zeichenfolge
   direkt schreiben.
4. Nicht auf "gruen" bauen, ohne den Exit-Code zu pruefen: wenn `./tests` nach
   dem Fix immer noch 0 liefert, ist das Grun dasselbe falsche Grun wie
   bisher. Das gehoert in den PR-Text.
5. Danach als Backports auf 25.0/25.1/25.2.

## Nebenbefund fuer die Flotte

Der Weg, auf dem die 15 Fremd-Commits in #3827 landeten, ist der bekannte:
`github pr mk-agent-clone` auf dem **Inkubator** statt auf dem Task-Branch.
Kontrolle, die es faengt: `git rev-list --count origin/release/<ziel>..HEAD`
muss 1 sein — beim Push sah es sauber aus, der PR wurde MERGEABLE.