---
name: backport-ours
description: "Backporting our own merged master commits/PRs down to the release lines (25.2 / 25.1 / 25.0), one PR per branch, on a per-task branch. Load when porting our own fix or feature to older releases, or when asked to backport a merged master PR. NOT for porting xorg/main — that is the backport-xorg-main skill."
---

# backport-ours — eigene master-Commits auf Releases

Dieser Workflow portiert **unsere eigenen** Commits aus gemergten master-PRs auf die
Release-Zweige. Für `xorg/main` gibt es `backport-xorg-main` — die beiden Workflows sind
verschieden, siehe `backport` (Router).

## Branch-Regel, und die ist nicht verhandelbar

**Ein Branch pro Task**, zum Beispiel:

```
rfc/backport-25.2-<task>          release/25.2
rfc/backport-25.1-<task>          release/25.1
rfc/backport-25.0-<task>          release/25.0
```

Der **nackte** `rfc/backport-<rel>` ist der xorg/main-Incubator und damit ein geteilter
Arbeitsplatz. Ihn für einen eigenen Task zu benutzen war am 2026-09-28 die Ursache für zwei
zerstörte Fremd-PRs und ist durch die Trennung in `backport-xorg-main` überflüssig.

## Schritt 1: Anwendbarkeit messen, nicht annehmen

Der Fehler ist auf jedem Release-Zweig **vorhanden** oder nicht — und ein Messfehler geht
direkt in einen leeren oder schädlichen Backport.

```sh
.starfleet-ai/bin/starfleetctl github backport applies <pfad> '<grep-ERE>' [release ...]
.starfleet-ai/bin/starfleetctl github pr show-branch-file release/<rel> <pfad> '<symbol>'
```

Pro Zweig klassifizieren: **vulnerable** / **already-fixed** / **N-A**. Nur für vulnerable
Zweige ein PR öffnen, den Rest dokumentieren.

**Gegenprobe, wenn das Werkzeug „file not found" meldet.** Es kann am falschen Repository
hängen. Die Existenz unabhängig prüfen, bevor man das als „nicht vorhanden" deutet:

```sh
git ls-tree origin/release/25.2 -- <pfad>          # Blob?
git show origin/release/25.2:<pfad> | wc -l         # Inhalt?
```

## Schritt 2: Cherry-Pick pro Zweig, ein PR je Zweig

```sh
.starfleet-ai/bin/starfleetctl github backport commit release/<rel> <commit-ish|PR#>
```

Das nimmt `cherry-pick -x` (Original-Subject und `Signed-off-by` bleiben, `(cherry picked from
commit <sha>)` wird angehängt) und legt den PR gegen `release/<rel>` an.

Nur ein echter Inhaltskonflikt bricht ab. Ein reiner **Pfad-Unterschied** aus dem
`Xext/<ext>/` ↔ `<ext>/`-Reorg wird automatisch umgeschrieben.

**Nur die Tip-Commits eines PRs werden aufgelöst.** Bei einem Mehrkommit-PR — etwa
„3749 + der Bugfix dazu" — beide Commits cherry-picken, sonst wandert der Bug in die Releases.
Das ist der wichtigste Einzelfall: **der Fix muss _vor_ dem Backport existieren, nicht danach.**

## Schritt 3: Build-Verifikation, pro Zweig

```sh
.starfleet-ai/bin/starfleetctl github pr mk-agent-clone <rel> <name>   # bzw. eigener Agent-Clone
```sh
.starfleet-ai/bin/starfleetctl github pr mk-agent-clone <rel> <name>   # bzw. eigener Agent-Clone
cd <Agent-Clone>
meson setup <build> . -Dwerror=true -Dxephyr=true -Dxnest=true -Dxvfb=true -Dxorg=true
ninja -C <build>
```

**Auf Release-Zweigen mit `-Dwerror=true` bauen, genau wie die CI es tut, und die Ausgabe gegen
eine bekannte Ausnahmeliste prüfen.** Es gibt genau **eine** vorbestehende Warnung, die hier mit
`-Werror` fehlschlägt:

    os/Xtranssock.c:631  -Werror=format-truncation

Alles **andere** in der Ausgabe stammt aus dem eigenen Backport. Die Gegenprobe einmal, danach
nicht mehr:

```sh
git checkout origin/release/<rel> && <build mit -Dwerror=true>   # erwarte nur Xtranssock.c:631
```

**Warum nicht `-Dwerror=false`.** Das war die frühere Empfehlung und sie hat eine Lücke
zugeschlagen, die real zugeschlagen hat: mit `-Dwerror=false` ist genau der Mechanismus
abgeschaltet, mit dem die CI-Lanes toten Code finden. Beim Backport von 3749/3752 stand
dadurch auf 25.2 und 25.1 ein mitgeschleppter, unbenutzter Helfer im Baum, lokal unsichtbar, und
die Lanes brachen mit

    error: unused function 'ms_is_running_virtual_gpu' [-Werror,-Wunused-function]

Der lokale Build lief mit Default-Warnstufe, die betroffenen Lanes bauen mit `-Dwerror=true` und
clang. Eine Fehlerklasse, die nur ein bestimmter Compiler mit bestimmten Flags findet, findet ein
lokales Setup ohne diese Flags nicht. Deshalb ist die Ausnahmeliste der eigentliche Gegenstand,
nicht die `-Dwerror`-Frage.
Belegt wird nicht „gebaut", sondern „gebaut **und** der Guard taucht im Objektfile auf":

```sh
strings <build>/<modul>.p/<datei>.c.o | grep -c '<der neue String>'
```

## Schritt 4: Cross-Link, und **kein** Merge

- Backport-Tabelle an den **Original-master-PR** hängen, eine Zeile pro Zweig mit Backport-PR
  und Status. PR-Bodies per REST ändern, `gh pr edit` scheitert am *Projects-classic*-Fehler.
- Jeder Backport-PR verlinkt zurück auf den Original-PR.
- **Release-Merges sind manuell, durch den Maintainer.** Ein `bot-review-passed` und grüne CI
  autorisieren keinen Merge in `release/*`. Auf `master` ist Auto-Merge nur bei expliziter
  Bitte des Nutzers zulässig.

## Backport-Würdigkeit, vorher

| zutrifft | |
|---|---|
| **ja** | Security-Lücke, client-auslösbarer Memory-Disclosure / OOB read-write / NULL-Deref / Use-after-free, Auth- oder Access-Control-Bypass, Crash & DoS, Datenkorruption, Regression |
| **nein** | Refactoring, Cleanup, Stil, neue Features, Build-System-Churn (außer es bricht ein Release-Build) |

Ein Merge auf `master` beweist **nicht**, dass der Fix backport-würdig ist. Der Master-PR kann
ein Refactoring sein, während derselbe Codepfad auf einem Release-Zweig einen NULL-Deref
trägt. **Deshalb immer gegen den Release-Zweig messen**, statt aus dem master-PR zu
schließen — der Fall ist real: bei `glamor_link_glsl_prog()` waren alle vier Master-Commits
Leckfixes, aber der Release-Zweig trug denselben ungeschützten `calloc` ohne Guard.

## Eigene Commits sind kein Feature-Backport

Führt ein Backport **neue** Funktionen, ein neues Struct-Feld und neue Verzweigungen auf einem
Release-Zweig ein, ist das ein **Feature-Backport**, kein Bugfix-Backport. Das ist eine bewusste
Feature-Entscheidung des Maintainers und gehört ihm, nicht als Nebenschritt in einen
Bugfix-PR. Beispiel: 3749 brachte `probe_if_is_running_single_size_hwcursor_gpu()`,
`ms_is_running_virtual_gpu()` und das Feld `fixed_size_cursor` — auf allen drei Release-Zweigen
null Treffer, weil sie mit 3749 erst auf master kamen. Der Zweig *kann* es nicht haben,
Merge-Base 25.2 ist vom 19.06., 3749 kam am 26.09.

## Reproduktion

```sh
# Verwundbarkeit je Zweig
.starfleet-ai/bin/starfleetctl github backport applies <pfad> '<grep-ERE>'
git ls-tree origin/release/<rel> -- <pfad>

# Branch wirklich frei?
gh pr list --repo X11Libre/xserver --head "rfc/backport-<rel>-<task>" --state open
```

## Cherry-pick-Konflikte im Backport: vier Typen, vier Behandlungen

Ein Konflikt beim Cherry-Pick sagt nichts über die Art. Am 2026-09-28 kam
`modesetting: use single sized hw cursor buffer` (#3749) auf 25.2/25.1 nicht
sauber durch, und die vier Konfliktarten verlangten vier verschiedene
Entscheidungen.

| Befund | Beispiel aus #3749 | Behandlung |
|---|---|---|
| **Pfad umbenannt** (Reorg) | `Xi/chgdctl.c` → `Xext/xinput/chgdctl.c` | Pfad umschreiben, Inhalt unverändert übernehmen |
| **Zusätzlicher Konflikt am selben Ort** | `drmmode_display.h`: `fixed_size_cursor` gegen `drmmode_legacy_cursor_probe_allowed()` | **Union bilden.** Beide Semantiken erhalten — 25.2/25.1 haben den Legacy-Guard, master nicht. „Merge-Resolution aus master übernehmen" ist falsch |
| **Gegensatz in einer Codezeile** | `dix/events.c`: `GRAB_STATE_FROZEN_WITH_EVENT` gegen `FROZEN_WITH_EVENT` | **Nicht** auf einer Seite entscheiden. Der Zielzweig hat die neuere Benennung, xorg die ältere. Erst klären, welcher Name in diesem Baum gilt, dann beide Seiten konsistent ziehen |
| **Datei fehlt im Ziel** | `dri3/meson.build` (wir haben `Xext/dri3/`) | Wenn die Datei umgezogen ist: Hunk auf den neuen Pfad anwenden und **prüfen, ob die Aussage dort noch gilt** — nicht blind |

**Vor jeder Konfliktauflösung zwei Fragen stellen**, in dieser Reihenfolge:

1. *Existiert die Datei im Zielzweig überhaupt?* `git ls-tree origin/<ziel> -- <pfad>`.
   Fehlt sie, ist es kein Code-Konflikt, sondern ein Pfad- oder Reorg-Fall.
2. *Ist der Konflikt nur Kosmetik oder verändert er Bedeutung?* Zwei Seiten
   vergleichen, die dasselbe tun, sind harmlos. Zwei Seiten, die **andere
   Bezeichner** nehmen, sind eine Entscheidung, keine Auflösung.

## Der teuerste Fehler: Definitionen entfernen, ohne die Aufrufer zu prüfen

Bei #3749 kam `ms_is_running_virtual_gpu()` als Überschuss aus dem
Konflikt-Hunk mit, ohne Aufrufer auf dem Zweig, also
`-Werror=-Wunused-function` auf FreeBSD/DragonFly. Entfernt — und damit
gleich `ms_window_has_async_flip()` mit, denn beide standen im selben Block.

Die async-flip-Helfer waren aber **vorbestehend und benutzt**: aufgerufen aus
`drmmode_display.c` und `present.c`. Ihr Entfernen erzeugte
`undefined symbol: ms_window_update_async_flip` im CI-`xorg_symbol_test`.
Der zweite Fehler war schlimmer als der erste, weil er nicht als
Compiler-Warnung auftritt sondern erst als Linkfehler des gebauten Moduls.

**Regel:** Eine Definition wird nur entfernt, wenn **der Aufrufer im Zielzweig
fehlt** — nicht, wenn der Aufrufer *anderswo* steht. Vor dem Entfernen immer
im Zielzweig prüfen:

```sh
git grep -c '<funktion>' origin/<ziel> -- <pfad>     # Aufrufer im Ziel?
```

**Und die Konsequenz, die ich gezogen habe:** Nach einem Drop-Commit
`grep` **über den ganzen Zielzweig** laufen lassen, nicht nur über die
Konfliktdatei. Ein Helper kann aus drei Dateien aufgerufen werden
(`drmmode_display.c`, `present.c`, `driver.c`).

Auf 25.0 war der Drop korrekt (dort existierten die async-flip-Heljer nicht),
auf 25.1/25.2 war er falsch. **Derselbe Commit, verschiedene Zweige, andere
Entscheidung** — das ist der Normalfall, nicht die Ausnahme.

## Wenn ein fremder Commit sich nicht 1:1 übernehmen lässt

`e19e86c29f` (modesetting, save cursor in master) rief `IsFloating()`, das
in unserem dix-Layer nicht existiert — dort heißt diePredicate
`InputDevIsFloating()` (`dix/input_priv.h`). Ein Cherry-pick hätte nicht
gebaut.

Das ist keine Blockade, das ist eine **Anpassung an die lokale API**, und sie
gehört in denselben Commit mit einer Zeile Begründung, die den Aufruf
benennt. Kein stilles Umbenennen, sonst sucht der nächste Lauf nach dem
Fehler.

## Bekannte Stolpersteine

- **Vor jedem Force-Push prüfen, ob der Branch einen offenen PR eines anderen Schiffs trägt.**
  Ein Board-Status ist kein Freifahrtsignal.
- **Vor dem Push sichern, nicht danach.** Der alte Tip als `refs/rescue/…` festhalten; die
  Wiederherstellung per `push --force-with-lease` mit dem *erwarteten* Wert, danach an Commits
  **und** Dateien verifizieren, nicht nur an der Branch-Spitze.
- **Ein Cherry-Pick kann Commits mitziehen, die der Zielzweig nie hatte.** Wenn der Build danach
  an unerwarteten Stellen bricht, sind das Zwischen-Commits aus dem Quellbaum, nicht der
  Backport. Überschuss entfernen und im PR-Body begründen, welcher Teil des Patches wirklich
  zum Auftrag gehört.
