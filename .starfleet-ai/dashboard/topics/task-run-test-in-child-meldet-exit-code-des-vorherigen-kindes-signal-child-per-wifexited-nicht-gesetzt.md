---
title: "run_test_in_child: child_failed nimmt den Exit-Code des VORHERIGEN Kindes (nur auf release/25.0 und 25.2)"
category: active
kind: task
status: assigned
assigned-to: "Barcley"
tags: "starfleet,xserver,test"
---

## KORREKTUR 2026-10-04 (Enterprise): die urspruengliche Praemisse war falsch

Dieser Task wurde zuerst mit der Begruendung erfasst, `./test/tests` gebe
exit 0 zurueck, obwohl ein Test `FAIL` meldet, und die Reihenfolge der
PRs haenge daran. **Beides war falsch.** Die Messung hinter der Behauptung
war ein Messfehler (eine Ausgabe zwischen Lauf und `$?`), und die daraus
abgeleitete Reihenfolge ist mit dem PR #3832 erledigt.

Gemessen, alle vier Zweige:

| Zweig | `child_failed:` | Exit bei Signaltod |
|---|---|---|
| `master` | `exit(EXIT_FAILURE)` (Z. 57) | 1 — korrekt |
| `release/25.1` | `exit(EXIT_FAILURE)` (Z. 30) | 1 — korrekt |
| `release/25.0` | `exit(exit_code)` (Z. 30) | **stale — latent** |
| `release/25.2` | `exit(exit_code)` (Z. 30) | **stale — latent** |

Der Mechanismus auf den betroffenen Zweigen:

```c
            if (!WIFEXITED(csts))
                goto child_failed;        // springt ueber die Zuweisung
            exit_code = WEXITSTATUS(csts);
            if (exit_code != 0) {
    child_failed:
                printf(" FAIL\n");
                exit(exit_code);          // Wert des VORHERIGEN Kindes
            }
```

Ein Kind, das von `assert()` per SIGABRT stirbt, erfuellt `WIFEXITED` nicht,
also wird `exit_code` nicht zugewiesen. Beim ersten Kind steht dort noch `-1`
(Exit 255), ab dem zweiten der Status des vorherigen — nach einem erfolgreichen
Vorgaenger also 0. **Dann geht ein brennender Assert als Erfolg durch.**

## Warum das praktisch relevant war

`master` hat es bereits behoben: `0bba12d19f` *"test: fail when a child
terminates abnormally"* hat `exit(exit_code)` auf `exit(EXIT_FAILURE)` umgestellt.
Dieser Commit kam ueber PR #3827 in die Release-Zweige. Ein wholesale-Revert
der 15 Fremd-Commits von #3827 haette die Haertung wieder entfernt — genau das
ist in der ersten Fassung von #3832 passiert und im Review aufgefallen.
Deshalb revertiert #3832 jetzt nur noch den Buildbrecher `82da0c6c45`.

**Merksatz:** Ein Revert ueber einen Bereich hinweg nimmt auch die *Fixes*
mit, die in diesem Bereich gelandet sind. „Alles zuruecknehmen, was nicht
zum Thema gehoert" ist keine guetige Regel, sobald der Bereich gemergt ist —
danach ist der Bereich Teil des Zweigs, mit Gutem und Schlechtem.

## Auftrag

1. `release/25.0` und `release/25.2`, je **ein** Commit, nichts weiter.
2. **Variante 2 bevorzugt:** die tote Zuweisung `exit_code = WEXITSTATUS(csts)`
   bzw. `int exit_code` ersatzlos streichen und immer `exit(EXIT_FAILURE)`
   nehmen — das macht den Fehler **unmoeglich** statt nur unbeachtet. Variante 1
   (`exit_code` im Signalpfad selbst setzen, `128 + WTERMSIG(csts)`) ist
   korrekt, laesst aber die Falle fuer den naechsten stehen.
3. Nachkontrolle, weil es hier der eigentliche Zweck ist: eine Suite, in der
   ein Test per Signal stirbt, muss **nicht null** liefern. Einmal mit
   absichtlich gerittenem Assert pruefen, dann melden — nicht nur bauen.
4. Fix-Richtung ist Release-Fix, kein master-Thema: auf `master` ist es bereits
   richtig.