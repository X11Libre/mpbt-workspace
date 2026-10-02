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

## Der Origin-Header gehört in jeden Backport-Commit

Ein auf den Release-Branch getragener Commit muss im Header erkennbar machen, woher er
kommt — sonst kann ein Reviewer auf dem Release-Zweig die ursprüngliche Diskussion nicht
finden.

- **eigene Commits** (von unserem master) — die Commit-ID genügt. `cherry-pick -x` liefert
  sie als `(cherry picked from commit <sha>)`, das ist bereits der passende Header.
- **externe Commits** (z.B. aus `xorg`) — ein **direkter Link in deren Repo**, nicht in unser
  eigenes. Die bestehende Form im Baum ist ein `Part-of:`-Trailer:
  `Part-of: <https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/2265>`

Zwei Dinge, die dabei leicht verwechselt werden:

- `Part-of:` zeigt nach **außen** (auf das Herkunftsprojekt). Das ist das Gegenteil des
  `[PR #NNNN]`-Markers, der nach **innen** auf unseren eigenen PR zeigt. Nicht mischen.
- Commits, die aus `xorg/main` kommen, tragen **keinen** `[PR #NNNN]`-Marker. Der Marker
  gehört zu unserem Inkubator-Ledger; ein Port eines xorg-Commits bleibt ein xorg-Commit.

Commit-Subjects bleiben ohne Präfix — siehe `bot-review` (Merge-Mode und Commit-Konventionen).

Nur ein echter Inhaltskonflikt bricht ab. Ein reiner **Pfad-Unterschied** aus dem
`Xext/<ext>/` ↔ `<ext>/`-Reorg wird automatisch umgeschrieben.

**Nur die Tip-Commits eines PRs werden aufgelöst.** Bei einem Mehrkommit-PR — etwa
„3749 + der Bugfix dazu" — beide Commits cherry-picken, sonst wandert der Bug in die Releases.
Das ist der wichtigste Einzelfall: **der Fix muss _vor_ dem Backport existieren, nicht danach.**

Diese Grenze war 2026-09-28 real: der Bugfix gegen den NULL-Deref aus #3749 lag als
eigener PR auf master, und der Release-PR wäre ohne ihn mit dem Absturz angekommen. Weil
beide Commits getrennt cherry-picked und **nicht** zusammengefasst wurden, ließ sich einer
später einzeln entfernen (siehe „Ein Commit aus der Mitte der Inkubator-Kette entfernen" in `backport-xorg-main`) — ohne die
übrigen anzurühren. **Ein Commit pro PR, kein Sammel-Commit:** Das macht den Backport
reparierbar, statt ihn unumkehrbar mit einem Fehler zu verkleben.

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

- Backport-Übersicht an den **Original-master-PR** hängen, **eine Zeile pro Zweig**. PR-Bodies
  per REST ändern, `gh pr edit` scheitert am *Projects-classic*-Fehler.
- Jeder Backport-PR verlinkt zurück auf den Original-PR.
- **Release-Merges sind manuell, durch den Maintainer.** Ein `bot-review-passed` und grüne CI
  autorisieren keinen Merge in `release/*`. Auf `master` ist Auto-Merge nur bei expliziter

### Die Referenzform: Liste, **keine** Tabelle, **keine** Links

In der Übersicht **keine** `bot-review-passed`-Klammern und **keinen** Status selbst
pflegen. Die Form ist eine **Task-Liste** mit bloßen Referenzen:

```
- [ ] GH-3801
- [ ] GH-3802
- [ ] GH-3803
```

**Gemessen am 2026-10-02** auf #3776, alle drei Formen nebeneinander:

| Form | Referenz | Ergebnis |
|---|---|---|
| Task-Liste | `GH-3801` | **klappt auf**, Titel + Status |
| Tabelle | `#3801` | nur die ID |
| Tabelle | `GH-3801` | nur die ID |

Es liegt am **Container**, nicht am Präfix. Die GitHub-Doku („Autolinked references
and URLs") nennt nur „in a list" — und sie hat damit recht, das Bild ist vollständig.
**Also: niemals eine Tabelle für die Backport-Übersicht.** Branch-Kontext kommt in
eine Zeile darüber oder in die Überschrift, nicht in Tabellenspalten.

Das Hover-Popup mit mehr Information ist davon **unabhängig**, war auch vorher schon
da und ist schwächer — es ist kein Ersatz.

**Warum ausdrücklich ohne Status-Spalte:** eine selbst gepflegte Spalte altert per
Definition. Am 2026-10-02 stand in einer solchen Tabelle „offen" bei #3802/#3803, die
seit Stunden gemergt waren — der Zustand war falsch, weil ihn niemand nachpflegte.
Der Listen-Eintrag kann nicht veralten, weil GitHub ihn beim Rendern auflöst.

**Und keine expliziten Markdown-Links** (`[#3813](https://…)`) auf PRs in der
Übersicht: die umgehen den Autolink-Mechanismus und damit den Live-Status. Genau
das war der Fehler vom 2026-10-02.

**Gleiches im Dashboard-Topic:** die Tabelle dort verlinkt die PRs, führt aber
**keine** eigene Status-Spalte. Merge-Status steht am PR selbst.

### Autor und Sign-off, wenn der Backport vom Original abweicht

Weicht die Auflösung **wesentlich** vom Upstream-Commit ab — Konfliktzonen anders
aufgelöst, Zeilen entfernt, die der Upstream-Commit nicht enthält —, ist der
Backport **ein eigener Write**, kein Transport. Dann:

- **Author und `Signed-off-by` sind derjenige, der ihn geschrieben hat**, nicht der
  Upstream-Autor. Die Fremd-Patch-Regel (Originalautor nehmen) gilt nur für
  unveränderte Übernahmen.
- Der `(cherry picked from commit …)`-Trailer **bleibt** als Herkunftsnachweis.
- Steht im PR-Body oder Commit-Text **ein Satz**, welche Zeile entfernt wurde, die der
  Upstream-Commit nicht enthält — sonst liest ein Reviewer es als Abweichung vom
  Original.

Beispiel 2026-10-02: #3793 auf 25.2/25.1. `pListHead` existiert dort nicht, der
Cherry-Pick konflizierte in fünf Zonen, und zwei tote Zeilen in
`damageSetWindowPixmap()` mussten entfernt werden, die der Upstream-Commit nicht
anfasst. Ergebnis: eigener Sign-off, plus die Begründungszeile im PR-Body.
  Bitte des Nutzers zulässig.

## Backport-Würdigkeit, vorher

| zutrifft | |
|---|---|
| **ja** | Security-Lücke, client-auslösbarer Memory-Disclosure / OOB read-write / NULL-Deref / Use-after-free, Auth- oder Access-Control-Bypass, Crash & DoS, Datenkorruption, Regression |
| **nein** | Refactoring, Cleanup, Stil, neue Features, Build-System-Churn (außer es bricht ein Release-Build) |

**Dieselbe Prüfung gilt für beide Workflows.** Ob ein Commit aus einem
eigenen master-PR oder aus `xorg/main` stammt: auf einem Release-Zweig
gehören **Bugfixes** hinüber, **keine Features**. Ein Commit, der ein
Verhalten hinzufügt statt es zu reparieren, wird nicht übernommen — und wenn
deshalb das Intervall nicht leer wird, bleibt der Tracker **stehen**. Ein
nicht leeres Intervall ist hier das richtige Ergebnis.

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

Auf 25.0 war der Drop korrekt (dort existierten die async-flip-Helfer nicht),
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
