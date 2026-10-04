---
title: "run_test_in_child: child_failed nimmt den Exit-Code des VORHERIGEN Kindes (nur auf release/25.0 und 25.2)"
category: active
kind: task
status: assigned
assigned-to: "Barcley"
tags: "starfleet,xserver,test"
---

## Stand 2026-10-04: PRs #3834 (25.0) und #3835 (25.2) stehen, Merge offen

| PR | Zweig | Commit | Quelle | Diff |
|---|---|---|---|---|
| #3834 | `release/25.0` | `2e0335e7e8` | `b799d88a78` (master) | +1/−1 |
| #3835 | `release/25.2` | `a2c7e82b33` | `b799d88a78` (master) | +1/−1 |

Beide MERGEABLE, 1 Commit, 1 Datei, genau **ein** Sign-off (Originalautor).
Herkunft ist bewusst der **Master-Original-Commit** `b799d88a78`, nicht der
25.1-Backport: so zeigen alle drei Zustaende auf **einen** kanonischen
Ursprung statt rueckwaerts. Commit-Nachricht unveraendert uebernommen, weil
es keine Abweichung vom Original zu dokumentieren gibt.

## Der Befund, der groesser ist als der Auftrag

Die Messung, mit der die Haertung belegt wurde, sagt mehr als "die Haertung
tut, was sie soll":

    XLIBRE_TEST=signal_logging_test ./tests

| Zweig | vorher | nachher |
|---|---|---|
| `release/25.0` | exit 0 | exit **1** |
| `release/25.2` | exit 0 | exit **1** |

jeweils mit ` FAIL` im Verdict. Auf 25.0 und 25.2 hat der Harness den
fehlschlagenden Assert also **gemeldet** und sich trotzdem mit 0 beendet.

**Folge:** der `signal_logging`-Assert ist auf **allen drei** Release-Zweigen
defekt. Auf 25.0/25.2 war er unsichtbar; auf 25.1 wurde er nur deshalb
sichtbar, weil #3827 die `exit(EXIT_FAILURE)`-Haertung mitgebracht hat.

**Damit machen #3834 und #3835 die Zweige, die heute gruen sind, rot** — an
einem Assert, der nicht von ihnen stammt. Deshalb braucht PR #3833 Backports
auf **alle drei** Release-Zweige, und die Reihenfolge lautet:

1. #3833 auf master mergen
2. Backport #3833 auf 25.0, 25.1, 25.2
3. #3831 mergen (gruen, bleibt gruen)
4. #3834, #3835, #3832 mergen (jetzt gruen)

## Zustand je Zweig (`child_failed:`)

| Zweig | Variante | Verhalten |
|---|---|---|
| `master` | `exit(EXIT_FAILURE)` | exit 1 — korrekt |
| `release/25.1` | `exit(EXIT_FAILURE)` | exit 1 — korrekt |
| `release/25.0` | `exit(exit_code)` | stale — latent, wird durch #3834 behoben |
| `release/25.2` | `exit(exit_code)` | stale — latent, wird durch #3835 behoben |

## Merksaetze, die dabei entstanden sind

- **Ein wholesale-Revert ueber einen gemergten Bereich nimmt die Fixes mit.**
  `0bba12d19f` / `b799d88a78` waren selbst Haertungen und landen mit unter
  den 15 "Fremd-Commits". Nach dem Merge ist ein Bereich Teil des Zweigs —
  mit Gutem und Schlechtem.
- **Der Testlauf, der eine Aenderung beweisen soll, muss gegen den Zustand
  laufen, in dem der Defekt sichtbar ist.** Ein gruener Lauf beweist fuer
  einen zurueckgenommenen Haertungsfix gar nichts — er beweist, dass die
  Haertung fehlt. Genau so ist die erste Fassung von PR #3832 gruen
  geworden.
- **Eine Einzelmessung ist keine allgemeine Aussage.** "exit 1 bei FAIL" auf
  master gemessen und als allgemeine Regel formuliert war auf 25.0/25.2 genau
  verkehrt herum.
- **`rc=$?` als naechstes Kommando, nie nach einer Ausgabe.**
