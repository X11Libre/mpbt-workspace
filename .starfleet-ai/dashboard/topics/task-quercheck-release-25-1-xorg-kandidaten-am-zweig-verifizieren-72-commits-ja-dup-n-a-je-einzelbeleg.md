Title: "Quercheck release/25.1: xorg-Kandidaten am Zweig verifizieren (72 Commits, JA/DUP/N-A je Einzelbeleg)"
Category: starfleet
Kind: "task"
Status: "in-progress"
Assigned-To: "Defiant-B"
Tags: "starfleet,xserver,backport,verifikation"

## Auftrag (Praetor: "ganze Flotte zur Hilfe")

Unabhaengige Zweig-Pruefung der xorg/main-Queue fuer **release/25.1**, damit **Interpid** (sein
Task: task-xorg-main-backport-phase-i-ii-release-25-1-...) nur das pickt, was tatsaechlich fehlt.
Ausloeser: Barcley hat bei drei Stichproben an den 21 "JA"-Kandidaten der 25.2er-Queue zwei
gefunden, die inhaltlich schon da waren (`d509580d02`, `da72833185`), obwohl `git cherry` alle 72
als fehlend meldet. Dieselbe Fehlerklasse wird hier fuer 25.1 unabhaengig gemessen.

**READ-ONLY.** Kein Pick, kein Push, `rfc/backport-25.1` tabu (gehoert Interpid).
Zusaetzlich gilt weiterhin: `rfc/backport-25.0` und alle tracking-/backport-Refse sind fuer dich
persoenlich tabu (Zuweisung 25.0 laeuft ueber [Defiant-A]) - dieser Quercheck beruehrt sie nicht.

## Vorbereitung

- Clone `_WORK_/xserver-25.1/sources/xlibre/xserver` (nur lesen), `git fetch xorg main`, `git fetch origin`
- Quell-Intervall: `origin/tracking/xorg/main-on-25.1..xorg/main` (Stand: Tracker `867976ba87`,
  `xorg/main` `ad26c26bf7` = **72 Commits** - selbst nachmessen)

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
   erledigt, **nicht duplizieren** - Geltung ergibt sich aus dem Kriterium, nicht aus der Position
   der Zeile (auch wenn dort "fuer master" notiert ist).
5. Schon entschiedene Grenzfaelle nicht neu entscheiden: `71c7824e80` (cpu_family) = weg,
   `309e4d35d8` = N/A, `2b9ce9f6c6` = JA, `dc8e08825a`/`84908e8db5`/`5422247702` = JA nach Zweig-Pruefung
   (eingetragen in der Auslassungs-Datei, Commit `9c3e9d831e`; Freigabe in m130871).

## Ergebnis

Tabelle `sha | subjekt (kurz) | Entscheidung | Beleg` ins **task log** UND per
`comms tell Interpid` (er pickt danach) + `comms tell Enterprise`. Vorher `comms status working`.
Echte Inhaltskonflikte/Struktur-Divergenzen extra melden (Pfad-Reorgs `Xi/` vs `Xext/xinput/`
trifft dich am ehesten - erst `git ls-tree` fragen).

**Nicht entscheiden:** Phase III (PR-Einreichung) startet erst nach Praetor-Freigabe (D1).

Weitere Details in Direktive m130892.

- 2026-10-07T18:25:40Z Defiant-B: began work

- 2026-10-07T18:25:46Z Defiant-B: Intervall SELBST GEMESSEN: origin/tracking/xorg/main-on-25.1=867976ba87 bis xorg/main=ad26c26bf7 -> rev-list --count = 72 (nach git fetch xorg main). READ-ONLY: rfc/backport-25.1 tabu (Interpid), kein Pick, kein Push.
