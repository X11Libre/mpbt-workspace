---
Title: "Audit 2026-10-01: fehlende Backports nach heutigem Merge (xkb-Serie 25.2, 3779 nach 25.0, 3775 alle Branches)"
Category: active
Kind: task
Status: open
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: 2026-10-02T00:00:00Z
Doc-Ref: "—"
---

Audit vom 2026-10-01, ausgehend von der Frage des Maintainers, ob alle heutigen
Merges den Backport-Prozess durchlaufen haben. Alle Zahlen gemessen, nicht
geschaetzt. Quelle: `gh pr list --state all` und `gh api .../check-runs`.

## 1. Heute gemergt: 17 PRs, davon 13 auf master

| base | Anzahl | davon mit bot-review |
|---|---|---|
| master | 13 | 12 |
| release/25.0 | 1 | 1 |
| release/25.1 | 1 | 0 |
| release/25.2 | 1 | 0 |

**Ohne jedes pr-review gemergt:**
- **#3770** `ci: bump dragonflybsd-vm` (master) — reiner CI-Bump, inhaltlich
  risikoarm, aber formal unreviewt.
- **#3759 / #3760 / #3761** `modesetting: single-size hw cursor` auf 25.2/25.1/25.0
  — das ist dieselbe Aenderung dreifach auf die Release-Linien, **ohne Review auf
  einer der drei**. Das ist der interessantere Befund: bei einer Security-relevanten
  Aenderung waere das ein echtes Loch, hier ist es ein Treiber-Fix, aber der
  Nachweis fehlt.

## 2. Backport-Stand und die Luecken, die gefunden wurden

Alle drei Batch-PRs sind inhaltlich **sauber** — Commit-SHA, Trailer-Kette und
Dateiliste je Branch geprueft:

| Master-PR | 25.2 | 25.1 | 25.0 |
|---|---|---|---|
| #3776 Xi ScrollClass flags | #3801 | #3802 | #3803 |
| #3777 test harness | #3800 | #3798 | #3797 |
| #3779 RegionValidate | #3794 | #3799 | **#3805** |

Pfad-Anpassung ist ueberall korrekt: #3801 nutzt `Xext/xinput/xiquerydevice.c`,
#3802/#3803 korrekt `Xi/xiquerydevice.c` (25.1/25.0 kennen `Xext/xinput/` nicht).

### BEFUND A — xkb-Serie unvollstaendig, der schwerwiegendste Commit fehlt

In **#3795 (25.1)** und **#3796 (25.0)** fehlt **#3783** `xkb: Guard
XkbAdjustGroup() against a keymap with no groups`. Drei Commits drin statt vier,
und die PR-Bodies nennen #3783 trotzdem — Dokumentation und Inhalt widersprechen
sich.

Warum das der schwerwiegendste der vier ist: er verhindert in `XkbAdjustGroup()`
bei einer Keymap ohne Gruppen drei Fehlbilder, die sein eigener Upstream-Kommentar
benennt — **Wrapping divided by zero** (SIGFPE), Clamping unterflowt auf -1, und
die Negativgruppen-Schleife **termniert nie**. Die anderen drei Commits klemmen
nur Werte ab (Default 1, nie 0, Clamp auf 4); dieser eine verhindert, dass ueberhaupt
hineingelaufen wird.

Messbar, und deshalb eindeutig: `gh pr diff 3795 | grep -c XkbAdjustGroup` -> **0**.

Dateipfade, gemessen: `xkbUtils.c` liegt auf master und 25.2 unter
`Xext/xkeyboard/`, auf 25.1/25.0 unter `xkb/`.

### BEFUND B — #3775 fehlt auf allen drei Linien

`(master) Xi: byte-swap DeviceChanged valuator and scroll data`, gemergt 17:00.
#3776 ist derselbe Fehlerklasse und liegt auf allen drei Linien. Wenn wir eines
zuruecknehmen und das andere liegen lassen, ist das halber Schutz ohne
erklaerbaren Grund.

### BEFUND C — 25.0 ist bei -Dwerror nicht strukturgleich

Die dokumentierte Einzelausnahme `os/Xtranssock.c:631` gilt auf 25.2/25.1. Auf
**25.0 existiert die Datei nicht** (0 Treffer im Build-Log, auf 25.1 dagegen 4), und
25.0 hat stattdessen fuenf vorbestehende Fehler in drei Dateien:
`glx/glxcmds.c` (-Werror=alloc-size-larger-than=), `glx/unpack.h:126/127`
(-Werror=unused-variable), `os/connection.c` (-Werror=stringop-truncation),
`os/xstrans.c` (-Werror=unused-variable).

Gegenprobe am **ungepatchten** 25.0-Tip `d9f34d33eb`: identische Fehlermenge,
identische FAILED-Targets. Der Commit fasst nur `dix/region.c` an.

**Konsequenz fuer die Doku:** wer auf 25.0 eine Einzelausnahme sucht, findet keine
und schliesst daraus "der Backport hat die Fehler verursacht" — das Gegenteil.
`backport-ours` und `xorg-main-backport-exclusions` brauchen eine
25.0-Sonderregel. Gemessen von Barcley, gcc 14.2.0.

### BEFUND D — Duplikat-PR, weil ich auf veralteter Messung gehandelt habe

#3805 (Barcley, 00:19) und #3806 (Interpid, 00:24) waren byte-identische Backports
desselben PRs auf denselben Branch. Ursache: mein Audit sagte "`#3779 -> 25.0`
fehlt", gemessen **bevor** Barcley es geschlossen hatte. Ich habe die Luecke
zugeteilt, ohne den Board daneben erneut zu lesen. #3806 ist geschlossen.

Merksatz: ein Audit, das ich auswerte, ohne den aktuellen Board zu lesen, ist eine
veraltete Messung mit Zeitstempel. Vor jeder Zuteilung neu messen.

## 3. Werkzeugbefunde (alle gemessen, gehen an Laforge)

1. **`github pr mk-agent-clone <branch>` legt auf dem nackten Inkubator an.**
   `origin/release/<x>...origin/rfc/backport-<x>` divergiert **pro Release
   unterschiedlich**: 25.2 `9 32`, 25.1 `2 6`, 25.0 `4 6`. Wer auf 25.1 nach
   "32 fremde Commits" sucht, findet nichts und haelt die Falle fuer harmlos.
   Kontrolle: `git rev-list --count origin/release/<branch>..HEAD` muss 0 sein.

2. **`mk-agent-clone 25.0` faellt aus** mit
   `reference clone not found: _WORK_/generic-25.0/sources/{project}` — es sucht
   `generic-25.0`, das Repo liegt unter `xserver-25.0`. Ueber `worktree add` mit
   explizitem Pfad ersetzt.

3. **`github pr` adressiert ohne `STARFLEET_GITHUB_REPO` das Workspace-Repo**
   (`ghpr.Repo()` macht `gh repo view` im CWD; ein mutierender Verb kann dadurch ins
   falsche Repo schreiben). Die Antwort steht in `project.yaml:5 upstream_repo`,
   wird aber nur von `UpstreamRepo()` gelesen, nicht von `Repo()`.

4. **`github pr job-logs` ist defekt** ("API error: exit status 1"). Logs gehen ueber
   `gh api repos/<o>/actions/jobs/<id>/logs`.

5. **`github pr merge` scheitert mit GraphQL-Fehler** ("failed to get PR info").

## 4. NICHT in die Backport-Queue — #3790

**#3790** `(master) xf86: mark wasset unused in xf86UnblockSIGIO() compatibility wrapper`
ist reviewed und **bewusst KEIN Backport-Kandidat**. Vom Maintainer am 2026-10-02
bestaetigt: aus der Queue der ausstehenden xorg-Backports **auslassen**.

Gemessen, nicht geschlossen:

- Der Diff ist eine Zeile: `_X_UNUSED` auf einen **bereits unbenutzten** Parameter
  eines `static inline`-Kompatibilitaerswrappers. `input_unlock()` nimmt kein Argument,
  die Aufruffolge ist identisch. **Kein Verhaltenswechsel.**
- Die Warnung, die der PR stumm schaltet, ist im Projektbuild **nicht aktiviert**:
  `-Wunused-parameter` kommt **null Mal** im CI-Compile vor, bei 46 verschiedenen
  `-W`-Flags. Es gehoert zu `-Wextra`, nicht zu `-Wall`, und `meson.build` setzt kein
  `-Wextra`. Sie feuert also nicht auf master und kann keinen Release-Build brechen.
- Keine Sicherheits- oder Korrektheitsdimension: nicht speicherunsicher, kein Crash,
  keine Datenkorruption.
- Die Funktion ist `_X_DEPRECATED`, sie **ist** der Kompatibilitaetsschirm fuer
  Pre-Input-Thread-Treiber. Nutzen hat ein Downstream-Consumer mit `-Wextra`/`-Werror`,
  der seine Flags selbst mitbringt.

**Rule 3 ist hier aus konstruktiven Gruenden beantwortet** und nicht ueber
Blob-Analyse: `static inline` in einem Header erzeugt **kein exportiertes Symbol** —
jede Translation Unit bekommt ihre eigene Kopie, es gibt nichts aufloesbares fuer die
NVIDIA-Blobs. `_X_UNUSED` ist `__attribute__((__unused__))` bzw. `/* */`
(`X11/Xfuncproto.h:169/171`), eine reine Diagnose-Attribut ohne ABI-Bedeutung. Damit
gibt es kein Symbol fuer `nvidia-abi-check` — das ist eine begruendete Aussage, kein
uebersprungener Schritt.

**Anwendbarkeit ehrlich begrenzt:** `xf86UnblockSIGIO` ist auf `release/25.2` in
identischer Form verifiziert. Auf `release/25.1` und `release/25.0` konnte ich
`include/xf86.h` ueber den API-Weg nicht lesen — ungeprueft. Das Votum aendert sich
dadurch nicht, weil es an den Build-Flags haengt, nicht an der Branch-Anwendbarkeit.

## 5. Offen

- `-Dwerror`-Doku um die 25.0-Sonderregel ergaenzen (gehoert in die Backport-Skills).
- Reviews der neun Backport-PRs stehen aus; auf `release/*` findet regulaer kein
  Review mehr statt. Zweite Augen sind dort mehr wert als neue PRs.
- #3770 / #3759 / #3760 / #3761 formal nachreviewen.