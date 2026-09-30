Title: "xserver master: macOS-CI-Break in miext/rootless (undeclared 'data')"
Category: xlibre
Kind: task
Status: "in-progress"
Created-By: "Enterprise"
Created: "2026-09-30T13:00:00Z"
Assigned-To: "Defiant"
Doc-Ref: "https://github.com/X11Libre/xserver/actions/runs/36697877070"
Slug: xlibre/task-ci-macos-break-rootless-undeclared-data

macOS-Lane rot auf master. Lauf 36697877070, Job xserver-build-macos, Commit
05b9873513. Gemessen, kein Infra-Flake:

    ../miext/rootless/rootlessScreen.c:141:26: error: use of undeclared identifier 'data'
       141 |         s->pixmap_data = data;

## Ursache

`924020906e` (PR #3559) wurde auf `d536dde7b4` angewendet. `d536dde7b4` hatte den
Block in `RootlessUpdateScreenPixmap()` bereits auf "erst in einen temporaeren Puffer
allozieren, dann den alten freigeben" umgeschrieben (Variable `new_data`). Die
Konfliktaufloesung hat `ModifyPixmapHeader()`/`devKind` nach aussen verschoben, aber
den Schwanz des aelteren Codes stehen gelassen. Ergebnis: zwei Allokationssequenzen in
einem Block — die zweite mit `free()` auf den gerade allozierten Puffer und dem nicht
mehr existierenden `data`.

Neben dem Compile-Fehler waere das ein **Double-Free** gewesen. Der Bug war also nicht
nur ein Build-Break.

PR #3559 selbst ist inhaltlich in Ordnung; nur die Aufloesung war falsch.

## Warum nur die macOS-Lane das sieht

`miext/rootless` wird ausschliesslich nach `hw/xquartz` gebaut, alle anderen Lanes haben
`xquartz` deaktiviert. Die Datei wird nirgends sonst kompiliert. Genau deshalb steht in
`d536dde7b4` der Hinweis, dass dort mit standalone `gcc -fsyntax-only` verifiziert werden
musste.

**Regel daraus:** eine Aenderung an `miext/rootless/` ist ohne macOS-Lane nicht
verifiziert. Der Umweg ueber `gcc -fsyntax-only` gegen generierte Config-Header ist
belegbar und billig:

    gcc -fsyntax-only -I<build> -I. -Idix -Imi -Iinclude -Imiext/rootless \
        $(pkg-config --cflags pixman-1) miext/rootless/rootlessScreen.c

## Release-Zweige nicht betroffen

| Branch | Befund |
|---|---|
| release/25.2 | sauber — hat `d536dde7b4` (`new_data`) |
| release/25.1 | sauber — deklariert `data` im eigenen Block korrekt |
| release/25.0 | sauber — deklariert `data` im eigenen Block korrekt |

Kein Backport noetig.

## Fix

Reine Loeschung von 4 Zeilen (3 Code + 1 Leerzeile). Die verbleibende
Allokationssequenz ist byte-identisch zu `release/25.2`, der Lane, die tatsaechlich baut.

Drei Schiffe haben unabhaengig denselben Fix gebaut; nur einer wird zum PR:

| Ship | Commit | Branch | Disposition |
|---|---|---|---|
| Defiant | `adad89d4d2` (amend von `fa79d183d4`) | `fix-macos-ci-break` | **PR wird eroeffnet** — Baum-Stand verifiziert |
| Laforge | `5a6d453d3d` | `wt/xserver-macos-fix` | zurueckgezogen, kein PR |
| Enterprise | `dba5952447` | eigener Agent-Clone | nie gepusht (0 remote-Treffer) |

Alle drei funktional identisch (Unterschied: eine Leerzeile). Enterprise hat Defiant die
Verifikation fuer den PR-Body uebergeben. Merge auf master ist Praetor-Entscheidung,
Enterprise hat nichts gemergt.

## Verifikation des PR-Baum-Stands (Enterprise, nach Amend)

Defiant hat `fa79d183d4` zu `adad89d4d2` amended. Am **Baum-Stand** verifiziert, nicht
am Commit-Subject:

| Pruefung | Ergebnis |
|---|---|
| Diff vs `origin/master` | genau die 3 Zeilen (`free` / `= data` / `= rowbytes`), sonst nichts |
| `gcc -fsyntax-only` gegen generierte Config-Header | EXIT=0 |
| `data` als Identifier in `RootlessUpdateScreenPixmap` | kein Treffer mehr (Rest: 2 Kommentare + Parameter von `RootlessWakeupHandler`) |
| `free()`-Reihenfolge | `calloc` → NULL-Check → `free(alt)` → `= new_data` → `memset`; kein `free()` nach Allokation |
| Abgleich | Allokationssequenz byte-identisch zu `release/25.2` |

Damit sind **beide** Defekte des Fragments erledigt: der Compile-Fehler und das latente
Double-Free.
