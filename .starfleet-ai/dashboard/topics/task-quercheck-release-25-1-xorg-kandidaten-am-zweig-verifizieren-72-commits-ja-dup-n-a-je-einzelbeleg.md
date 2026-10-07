---
title: "Quercheck release/25.1: xorg-Kandidaten am Zweig verifizieren (72 Commits, JA/DUP/N-A je Einzelbeleg)"
category: starfleet
kind: task
status: assigned
assigned-to: "Defiant-B"
tags: "starfleet,xserver,backport,verifikation"
---

## Auftrag (Praetor: "ganze Flotte zur Hilfe")

Unabhaengige Zweig-Pruefung der von Barcley klassifizierten xorg/main-Queue fuer **release/25.1**,
damit er pickt, was tatsaechlich fehlt. Ausloeser: Barcley fand bei drei Stichproben an den
21 "JA"-Kandidaten **zwei, die inhaltlich schon da waren** (`d509580d02`, `da72833185`), obwohl
`git cherry` alle 72 als fehlend meldet.

**READ-ONLY.** Kein Pick, kein Push, `rfc/backport-25.1` tabu (gehoert Barcley, m130892).

## Vorbereitung

- Clone `_WORK_/xserver-25.1/sources/xlibre/xserver` (nur lesen; bei Schreibbedarf eigenen
  Worktree `starfleetctl worktree add`), `git fetch xorg main`, `git fetch origin`
- Quell-Intervall: `origin/tracking/xorg/main-on-25.1..xorg/main` (Stand: Tracker `867976ba87`,
  `xorg/main` `ad26c26bf7` = **72 Commits** — selbst nachmessen)

## Methode, je Commit

1. `git show --name-only <sha>` -> **Dateiliste** (nicht das Subject)
2. Klassifizieren:
   - **XWL**: nur `hw/xwayland/` | **GHC**: nur `.gitlab-ci*`
   - **N-A**: Zielcode fehlt -> `git grep -c <symbol> origin/release/25.1 -- <pfad>`; 0 Treffer = N-A
   - **DUP**: Inhalt schon da -> `git grep -n '<distinctiven String>' origin/release/25.1 -- <pfad>` bzw. `git log -S`
   - **NEIN (Release-Regel)**: neue Option/Funktion/Feld, Refactoring, Kommentar/Format
   - **JA**: Korrektheit/Absturz/Sicherheit/Build-Fix
3. Fuer JA und DUP **immer den Beleg** mitschreiben: Kommando + Trefferzahl. Ohne Beleg gilt die Zeile nicht.
4. Bereits in `agents.d/xlibre/xorg-main-backport-exclusions.md` stehende SHA (17 Stück) gelten als
   erledigt, **nicht duplizieren** — Geltung ergibt sich aus dem Kriterium, nicht aus der Position
   der Zeile (auch wenn dort "fuer master" notiert ist).

## Ergebnis

Tabelle `sha | subjekt (kurz) | Entscheidung | Beleg` ins **task log** UND per
`comms tell Barcley` (er pickt danach) + `comms tell Enterprise`. Vorher
`comms status working`. Echte Inhaltskonflikte/Struktur-Divergenzen extra melden.

**Nicht entscheiden:** Phase III (PR-Einreichung) startet erst nach Praetor-Freigabe (D1).
Diese Messung ist keine Freigabe.

Weitere Details in Direktive m130892.
