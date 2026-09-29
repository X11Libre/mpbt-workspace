---
name: backport-xorg-main
description: "Porting new xorg/main commits onto an XLibre target branch (master or a release line) via the per-target tracker and incubator branches. Load when syncing from xorg/main, when working on rfc/backport-* incubator branches, or when a tracking/xorg/main-on-* tracker is behind xorg/main. NOT for backporting our own master commits — that is the backport-ours skill."
---

# backport-xorg-main — xorg/main → ein Target-Branch

Dieser Workflow portiert **Commits von `xorg/main`** auf **ein** Target-Branch. Für eigene
Commits aus unseren master-PRs gibt es `backport-ours` — die beiden Workflows sind verschieden
und nicht austauschbar, siehe `backport` (Router).

Der Workflow läuft **pro Target vollkommen unabhängig** und **immer im Clone, der zu diesem
Target gehört**: `_WORK_/xserver-master` für master, `_WORK_/xserver-25.0` / `-25.1` / `-25.2`
für die Releases. Es sind getrennte mpbt-Clones mit getrennter `make-pr.*`-Konfiguration.

## Die gemeinsamen Inkubator-Regeln stehen im Router

Rebase-Kadenz, das `[PR #NNNN]`-Ledger, das **Abbrechen bei noch ungemergten PRs** (mit den
verrückten Konflikten, die man nicht auflösen, sondern aussitzen soll) und die Clone-zu-target-
Zuordnung stehen in `backport`. Hier nur das, was spezifisch für `xorg/main` ist.

## Die beiden Branches pro Target

| Branch | Rolle |
|---|---|
| `tracking/xorg/main-on-<target>` | **Tracker**: der letzte `xorg/main`-Commit, den wir für dieses Target **bearbeitet** haben. Alles bis dahin ist erledigt: gemergt, in einem offenen PR, oder bewusst ausgelassen. |
| `rfc/backport-<target>` | **Incubator**: die Queue der noch nicht eingereichten `xorg/main`-Commits, rebased auf den Target-Branch. |

`rfc/backport-<target>` ist ein **geteilter** Branch. Er sammelt laut Definition immer
Commits, die in `<target>` wandern sollen, und dient **auch** als WIP-Sammelstrecke, aus
der fertige Stücke isoliert herausgezogen werden. Geteilter Branch — er ist die Queue, nicht ein privater
Arbeitsplatz. Commits, die bereits als PR eingereicht wurden, tragen den Marker `[PR #NNNN]`
im Subject; den setzt `scripts/xx-make-pr.sh`, und dieselbe Stelle entfernt ihn wieder, wenn der
Incubator auf den Submission-Branch rebased wird. **Dieses Subject-Marking ist das Ledger.**
Deshalb weichen die SHAs im Incubator zwangsläufig von `xorg/main` ab: Rewriting plus Rebase
auf den Target-Branch ergeben andere Hashes. Das ist kein Fehler, sondern zu erwarten.

## Harte Vorbedingungen

1. **Im richtigen Clone arbeiten.** `xx-make-pr.sh` liest `make-pr.upstream-remote`,
   `make-pr.upstream-branch` und `make-pr.reviewers` aus dem **aktuellen** Repos `.git/config`.
   Im falschen Clone submitted man Backports im falschen Kontext und findet sie später nicht.
2. **Vor jedem Force-Push auf `rfc/backport-<target>` prüfen, ob dort ein offener PR eines
   anderen Schiffs liegt.** Genau diese eine Prüfung wurde am 2026-09-28 zweimal versäumt und
   hat einmal 20 fremde Commits und einmal einen Backport zerstört. Der Board-Status sagt
   nichts darüber aus, ob der Branch frei ist.
3. **`xwayland` und andere bewusst entfernte Bereiche werden ausgelassen**, ebenso
   **zweig-spezifisch**, und **je Zweig einzeln messen**. Das gilt besonders für
   **`.gitlab-ci/`-Bereich**: auslassen, aber NUR die Commits, die **ausschließlich**
   `.gitlab-ci/` betreffen. Wir haben GitLab-CI entfernt und nutzen nur GitHub CI, der
   Ordner existiert hier also nicht. Achtung: nicht den ganzen Commit verwerfen, weil
   CI-Anpassungen intern oft zusammen mit anderen Aenderungen laufen (z. B. wenn sich eine
   Dependency aendert). Entscheidend ist die **Dateimensge**, nicht das Subject: hat der
   Commit neben `.gitlab-ci/` auch echten Quellcode oder Build-Dateien, werden diese Teile
   uebernommen und nur die CI-Dateien fallen weg.

   **Die CI-Dateien sind kein Muell.** Bevor ein `.gitlab-ci/`-Commit verworfen wird,
   lohnt der Blick auf den Inhalt: CI installiert oft Abhaengigkeiten, und eine
   Aenderung dort spiegelt eine Anforderung des gleichzeitigen Codes wider. Beispiel:
   verlangt ein Commit neueres `xorgproto` (z. B. `>= 2025.1` fuer `_X_FALLTHROUGH`),
   steht das in der CI-Install-Zeile des Upstream. Dann muss auch unsere eigene github-CI
   das neue `xorgproto` liefern, sonst schlaegt unser Lauf genau dort fehl. Der CI-Block
   ist also ein **Signal**, das in die Betrachtung gehoert, nicht nur ein Auslass-Kandidat.
   Faustregel: Wenn der ausgefallene CI-Teil eine Abhaengigkeits-Anforderung nennt, die
   der uebernommene Code braucht, als eigene Notiz zur CI-Anpassung fassen.
   (Ob unsere CI das im Lauf sichtbar macht, ist ein Nebenprodukt, keine Garantie: ein
   fehlendes Paket faehrt erst auf, wenn der Build es wirklich braucht.)
   xorg-Testskripte: `test/pyxtest` ist **nicht** auf master beschränkt, es existiert
   mit identischem Umfang auch auf `release/25.2` (42 Einträge auf beiden, gemessen am
   2026-09-28). Eine pauschale Annahme wie „die Tests nehmen wir nur mit master" ist
   falsch. Auslassungen gehören
   **vor** den Lauf in den Task/Plan, nicht hinterher in einen PR-Body.

## Die drei Phasen

### I. Incubator auf den Target-Branch rebasen

Damit fallen bereits gemergte Commits automatisch wieder heraus, und Konflikte mit dem
Target-Branch werden früh sichtbar.

```sh
cd <Clone des Targets>          # z. B. _WORK_/xserver-25.2/sources/xlibre/xserver
git fetch origin --prune
git checkout rfc/backport-25.2
# Vor dem Force-Push: ist der Branch gerade in Gebrauch?
gh pr list --repo X11Libre/xserver --head rfc/backport-25.2 --state open
git rebase make-pr.upstream-branch    # bzw. origin/release/25.2
git push --force-with-lease origin rfc/backport-25.2
```

`--force-with-lease` ist hier Pflicht, nicht Kosmetik: Phase I schreibt auf einen geteilten
Branch.

### II. Fehlende Commits aus `tracker..xorg/main` übernehmen

```sh
git fetch xorg main
git log --oneline origin/tracking/xorg/main-on-25.2..xorg/main   # was fehlt
```

Aufnahme in den Incubator, wahlweise per `--onto`-Rebase oder sequenziellem Cherry-Pick. Was
ausgelassen wird, wird **nicht** aufgenommen und **nicht** über den Tracker abgehakt.

Danach den Tracker so weit hochziehen, dass die bearbeiteten Commits beim nächsten Durchlauf
nicht erneut drankommen, und **Incubator wie Tracker** pushen. Beides soll **Fast-Forward**
sein, **keine Merge-Nodes**.

```sh
git branch -f origin/tracking/xorg/main-on-25.2 <letztes bearbeiteter xorg/main-Commit>
git push origin tracking/xorg/main-on-25.2
```

Optimalerweise steht der Tracker danach auf `xorg/main` selbst, also `origin/tracking/…` und
`xorg/main` sind identisch und das Intervall ist leer.

### III. Commits einzeln als PR einreichen

Schrittweise, nicht alle auf einmal, damit die Review-Last und der Konfliktradius klein bleiben.

```sh
# im Clone des Targets, HEAD ist der Incubator
scripts/xx-make-pr.sh <commit> [<commit> ...]           # --branch <name> optional
```

Das Skript legt einen temporären Submission-Branch an, cherry-pickt die Commits, pusht, eröffnet
den PR, **schreibt den `[PR #NNNN]`-Marker in die Subjects** und rebased den Incubator auf den
Submission-Branch, sodass die eingereichten Commits mit Marker unten liegen.

Danach `origin` und lokal vergleichen: **die Trees müssen gleich sein, die History darf
abweichen.** Erst dann force-pushen.

**Nach Thema grupieren, nicht Commit für Commit.** Ein PR pro Commit bedeutet
20 PRs für 20 Commits, auch wenn fünf davon dieselbe Datei betreffen und nur
gemeinsam sinnvoll prüfbar sind. Nach dem Anwenden von Phase II ist die
übliche Grouping-Form:

| Gruppe | Umfang |
|---|---|
| Ein logischer Fix | zusammengehörige Commits, die dieselbe Datei/ denselben Codepfad betreffen (z. B. der xkb-Block, ein Xi-Byte-Order-Block, die meson-Konvertierungen) |
| Ein Commit | alles, was thematisch für sich steht |

Ein PR muss für sich reviewbar sein. Ein Sammel-PR über 20 gemischte Themen
ist das Gegenteil, auch wenn er weniger Klicks spart.

**Den ersten Lauf als Probe machen.** `xx-make-pr.sh` schreibt auf dem
Inkubator um und ist damit nicht gefahrlos. Beim ersten Mal in einem
Workspace deshalb mit **einem** Commit starten, Push und PR prüfen, und erst
dann fortsetzen. Nicht alle 20 auf einmal — ein Fehler in der Mechanik
sonst einmal für alle.

**Nach jedem Lauf prüfen, nicht nur am Ende.** Nach jedem `xx-make-pr.sh`:
steht der neue PR offen, trägt der Incubator-Commit den `[PR #NNNN]`-Marker,
und ist der Incubator um genau diese Commits kürzer geworden. Der Marker ist
das Ledger; fehlt er, wird beim nächsten Durchlauf doppelt eingereicht.

**Bricht das Skript mit verrückten Konflikten ab, ist das eine Blockierung durch noch
ungemergte PRs, keine kaputte Basis.** Nicht auflösen, sondern liegen lassen, bis zum nächsten
Rebase auf die target-branch neu versuchen — in der Regel ist der blockierende PR dann gemerged.
Wer das nicht kennt, erzwingt Konflikte und macht aus einer Warteschleife eine Scheinlösung.

## Wo die Auslassungen dokumentiert sind

Kanonisch ist **`agents.d/xlibre/xorg-main-backport-exclusions.md`** im Workspace,
versioniert auf `mtx/agent-config`. Nicht in `_WORK_/` — das ist nicht versioniert und
überlebt keinen Reset. Nicht im Inkubator — `.backport-skips` wurde verworfen, weil eine
Datei auf einem geteilten, gepushten und gelegentlich neu aufgesetzten Branch
verlorengehen kann, während die versionierte Datei das nicht kann.

Der Preis dieser Wahl ist Discoverability: wer den Inkubator öffnet, sieht die
Auslassungen nicht. Deshalb steht hier der Verweis, und der Task-Log des
xorg/main-Backports verweist ebenfalls darauf.

## Der Target wird ausschließlich über PRs weitergeschrieben

In diesem Workflow wird **kein** Target-Branch direkt gepusht oder gemergt — weder `master` noch
`release/*`. Phasen I und II pushen auf `rfc/backport-<target>` und `tracking/xorg/main-on-<target>`,
Phase III reicht PRs ein. Das ist der Weg.

Grund: dass bereits gemergte Commits beim Rebase automatisch aus der Queue fallen, setzt
voraus, dass der Target über PRs vorankommt. Ein direkter Merge macht den Tracker-Fortschritt
unüberprüfbar und erzeugt beim nächsten Rebase Konflikte über Commits, die nie reviewt wurden.
Die vollständige Regel steht im Router unter „Merge-Grenze".

## Einzelfall, der vor dem Einreichen zu entscheiden ist

Patch-Äquivalenz ist nicht inhaltliche Enthaltenheit. Beispiel aus dem aktuellen Intervall
(Stand 2026-09-28): `316321933a glamor: free the link log on shader link failure` ist das
Upstream-Gegenstück zu unserem gemergten PR #3750 (`482f7b326d`). `git cherry` meldet es als
fehlend, weil unser Fix ein eigener Patch ist und kein Cherry-Pick. Inhaltlich deckt unser Fix
das ab und ist der vollständigere, weil er den `calloc`-Guard mitbringt. Solche Commits gehören
ausgelassen und **in `agents.d/xlibre/xorg-main-backport-exclusions.md` begründet** —
nicht eingereicht und später bereinigt. Dateiformat und die Begründung, warum die
Ablage versioniert und nicht im Inkubator liegt, stehen im Router unter
„Auslassungen festhalten“. Die Auslassungsentscheidung gehört **vor** den Lauf.

## Entscheidungspunkte → immer einen Entscheidungsreport

An jedem Ort, an dem der Praetor eine Entscheidung treffen muss, wird **kein Chat-Text**,
sondern ein **`reports submit`** mit einer klar erkennbaren **Entscheidungsvorlage** abgelegt
— die er lesen, ggf. bearbeiten und dann freigeben kann. Chat-Kommentare sind flüchtig und
gehen in der Fortsetzung verloren; der Report bleibt im Fleet-Archiv.

Wo dieser Punkt liegt: mindestens **vor Phase III** (welche Kandidaten werden eingereicht,
welche ausgelassen) und bei jedem **Auslassungs-Konflikt** (z.B. DUP-Fälle wie `316321933a`).
Die Vorlage muss enthalten:

- **Entscheidungspunkt**: was genau freizugeben oder zu entscheiden ist (ein Satz).
- **Optionen** mit Vor- und Nachteilen (ein Satz je Option), eine davon als Empfehlung
  markiert.
- **Status-Ecke**: Tracker-Stand, xorg/main-Stand, Zahl der Kandidaten, Zahl der
  Auslassungen, Referenz auf die versionierte Auslassungs-Konvention.
- **Was nach der Entscheidung passiert**: der konkrete nächste Schritt (z.B. „Phase III:
  17 clean + 9 Konflikte einzeln einreichen").

`reports submit "…" --task-ref <task> --body-file <file>` — Titelsuffix „Entscheidung
erforderlich" macht die Antwortpflicht sichtbar. Erst die Freigabe des Praetors auf den
Report (per comms) löst den nächsten Schritt aus; kein eigenmächtiges Weiterspringen über
einen Entscheidungspunkt hinweg.

## Was nicht mehr dazugehört

Eigene Commits aus unseren master-PRs in den Incubator zu legen war früher üblich und ist
**Auslaufmodell**, weil wir inzwischen PR-Dashboards haben. Für eigene Commits gilt
`backport-ours` mit einem eigenen Branch pro Task.

### Weggeworfene CI-Dateien sind ein Frühwarnsystem

Wenn `.gitlab-ci/*`-Dateien ausfallen, ist das **kein Informationsverlust**, solange man
bewusst wegschaut — es ist eine verpasste Warnung. Der Upstream-CI-Block ist oft die
**einzige** Stelle, an der eine neue Abhängigkeitsanforderung früh und maschinenlesbar
steht. Beispiel: `xorg/main:.gitlab-ci/debian-install.sh:139` sagt
„xserver requires xorgproto >= 2025.1 for _X_FALLTHROUGH" — genau die Anforderung, an der
unser `wip/fallthrough`-Branch hängenbleibt. Verwerft man den CI-Teil ersatzlos, fällt
das erst auf, wenn der Code die Abhängigkeit wirklich braucht, also mitten im Lauf.

**Faustregel:** bei jeder Auslassung von `.gitlab-ci/*` den CI-Inhalt auf
Abhängigkeitsanforderungen ansehen. Braucht der übernommene Code eine solche Anforderung,
dann als **eigene Notiz** festhalten — nicht in der Auslassungszeile verstecken, sondern
als offene CI-Aufgabe mit Bezug auf den Commit. Der Nicht-CI-Teil des Commits wird
trotzdem übernommen (siehe Kriterium GHC).

## Konflikte klassifizieren, bevor man sie zählt

Ein `cherry-pick`, der abbricht, liefert eine Liste unaufgelöster Pfade. Die Liste
ist **keine** Konfliktliste — sie mischt drei Dinge, die getrennt behandelt
gehören:

| Befund | Bedeutung | Behandlung |
|---|---|---|
| `UU`/`AA` in einer Datei, die im Ziel existiert | echter Inhaltskonflikt | manuell, mit Semantik prüfen |
| `DU`/`UD` an einer Datei, die im Ziel existiert | delete/modify | Zielzustand entscheiden |
| `DU`/`UD` an einer Datei, die im Ziel **nicht existiert** | Datei fehlt im Zielbaum, meist CI-Konfig | **kein Code-Konflikt** — Hunk entfällt ersatzlos |

**Die dritte Klasse wird routinemäßig als Code-Konflikt fehlklassifiziert.** Am
2026-09-28 meldete `bd3ca7da06` 12 „Konfliktdateien", darunter drei
`.gitlab-ci*`, die es in unserem Baum nicht gibt. Erst die Gegenprobe
`git merge-base --is-ancestor <commit> <inkubator-tip>` trennt die Klassen.

**Reihenfolge bei jedem Konflikt:** erst `git ls-tree <ziel> -- <pfad>` (existiert
die Datei im Ziel?), dann `merge-base` gegen den Inkubator-Tip (ist der Commit
überhaupt in der Kette?), dann erst über Inhaltskonflikt urteilen. Erst drei
solcher Fehlklassifikationen fielen auf — eine davon führte dazu, dass ein Backport
als „Fremd-PR" gemeldet wurde, obwohl es die eigene PR #3364 war.

## Ein Commit aus der Mitte der Inkubator-Kette entfernen

Kommt vor, wenn ein Commit im Inkubator überholt ist: er ist keine xorg/main-Fassung
mehr, oder er ist eine eigene Master-PR, die dort liegen geblieben ist. Ein solcher
Commit bricht bei **jedem** Gesamtbuild identisch und wird dabei leicht als „fremde
Ursache" fehlattribuiert — 2026-09-28 stand `516b44f3f1` so im Inkubator (unsere PR
#3364, nicht xorg/main) und erzeugte fünf Build-Fehler in `disconnect.c`.

Zwei saubere Wege, in dieser Reihenfolge:

```sh
# Standard: rebase onto, der entfernte Commit fällt raus
git rebase --onto <neuer-parent> <zu-entfernender-sha> <branch>

# Alternative: die Restcommits frisch auf eine saubere Kette setzen
git cherry-pick <restliche-commits>          # auf origin/<neuer-parent>
```

**Vorher sichern, danach prüfen.** Vor dem Umbau den alten Tip als
`refs/rescue/<branch>-pre-drop` festhalten; den Push mit `--force-with-lease`
gegen genau diesen bekannten Wert. **Nachher verifizieren**, sonst ist der Drop
der nächste Fehler:

```sh
git rev-list --count <parent>..<branch>        # Anzahl vorher notiert?
git log --oneline <parent>..<branch>           # stimmt die Reihenfolge?
git fsck --no-progress 2>&1 | head             # existieren alle SHAs der Kette noch?
```

**Niemals** `git filter-branch` und **niemals** ein `update-ref` ohne diese Prüfung.
Ein Force-Push auf den Inkubator ist Normalbetrieb, nicht schon an sich ein Vorfall —
aber die Wiederherstellbarkeit kommt vorher, nicht nachher.

## Der Inkubator-Mechanismus, der Phase III entscheidet

Vier Dinge, die beim Einreichen und beim Rebase zusammenwirken. Alle am
2026-09-28 gemessen.

### Ein bereits gemergter Commit fällt nur bei Patch-Identität heraus

`git rebase` droppt einen Commit als „zuvor angewendet", wenn der **Patch
identisch** im neuen Ziel liegt — nicht wenn er inhaltlich dasselbe tut.

```
git show <commit> | git patch-id --stable | cut -d' ' -f1
```

Gleiche Patch-ID → Git droppt beim nächsten Rebase von selbst, kein Hand-Edit.
**Verschiedene Patch-ID → bleibt liegen**, auch wenn der Commit inhaltlich
bereits erledigt ist, und bricht jeden Build identisch. Am 2026-09-28 war das
PR #3547: der Queue-Commit war patch-verschieden vom inzwischen auf master
gereihten PR-Head (9 Dateien, 65/117), also wäre er **nicht** automatisch
gefallen. Wer das annimmt, wartet vergeblich auf einen Merge.

Umgekehrt gilt das für den **eingereichten** Commit: nimmt man einen
reparierten PR-Head in den Inkubator auf, ist er patch-identisch zum
PR-Head und fällt später automatisch heraus. Genau das ist der Grund, einen
Tausch sauber zu machen statt ihn zu verschieben.

### Der `[PR #NNNN]`-Marker gehört in den Commit-Subject

Beim Einsetzen eines fremden PR-Commits in den Inkubator den Marker
**wieder setzen**. Er entsteht sonst nur auf dem Submission-Branch und geht
beim Übernehmen verloren, und der Inkubator zeigt nicht mehr, dass etwas schon
eingereicht war. Im Body zusätzlich festhalten, **welchen** Queue-Commit er
ersetzt und warum (nicht baubar, inzwischen upstream).

### Position prüfen, nicht annehmen

Ein `cherry-pick` legt **immer auf HEAD**. Wer einen Commit an einer
bestimmten Position der Kette einsetzen will, darf nicht auf HEAD picken und
danach hoffen, dass er richtig landet. Zwei Weile, die funktionieren:

- alles bis zur Einfügeposition als Basis setzen, dort picken, den Rest in
  **alter Reihenfolge** wieder anhaengen (`git rev-list --reverse` vom alten Tip)
  — so wird die Position konstruktiv erhalten;
- oder die vollständige geordnete Liste der Commits einmal abnehmen und
  neu aufbauen, Position für Position.

Immer danach messen: Commit-Anzahl, ob der neue Commit an der erwarteten
Position sitzt, ob der ersetzte wirklich raus ist.

### `checkout --detach` auf einen Punkt außerhalb des Ziels zerlegt die Kette

`git checkout --detach <sha>` setzt den Zeiger auf **diesen** Commit, nicht auf
das Ziel. Ist `<sha>` nicht auf `origin/master`, zeigt `rev-list --count
origin/master..HEAD` plötzlich weit weniger Commits — die unterhalb liegenden
gehören dann nicht mehr zur Kette. Man hat nicht „nichts angefasst", man hat
die Kette zerschnitten.

Vor jedem Umbau: Ausgangspunkt notieren, und wenn die eigene Zählung
plötzlich einstellig ist, **die Ausgabe lesen, nicht den Exitcode**. Genau das
ist am 2026-09-28 zweimal schiefgegangen, mit Auswirkung auf Position, nicht
auf den Inhalt.

## Ist-Zustand (Stand 2026-09-28, vor dem ersten Lauf messen!)

Nicht ungeprüft übernehmen, das hier ist eine Momentaufnahme und dient nur der Größenordnung:

- alle vier Tracker auf `867976ba87` (20.08.), `xorg/main` bei `b125b19fc2`
- 33 offene Commits, davon 6 ausschließlich `xwayland` (auszulassen), 27 in Frage kommend
- 67 Dateien, +441/−185
- der Spitzen-Commit war ein `xwayland`-Commit, also die erste Zeile, die ausfällt

## Reproduktion

```sh
# Tracker-Stand je Target
git fetch xorg main
for t in master 25.0 25.1 25.2; do
  printf '%s %s %s\n' "$t" \
    "$(git rev-parse --short origin/tracking/xorg/main-on-$t)" \
    "$(git rev-list --count origin/tracking/xorg/main-on-$t..xorg/main)"
done

# Bereichsgruesse des Rueckstands
git diff --shortstat origin/tracking/xorg/main-on-25.2 xorg/main

# nur-xwayland-Kandidaten, die auszulassen waeren
git log --format=%H origin/tracking/xorg/main-on-25.2..xorg/main |
  while read c; do git show --name-only --format='' "$c" |
    grep -qE '^hw/xwayland/' && ! git show --name-only --format='' "$c" |
    grep -qvE '^hw/xwayland/' && echo "$c"; done

# Inkubator: in Gebrauch?
gh pr list --repo X11Libre/xserver --head rfc/backport-25.2 --state open
```

## Bekannte Stolpersteine

- **`-Dwerror=true` ist auf den Release-Zweigen als Prüfkriterium unbrauchbar.** Der Build bricht
  in `os/Xtranssock.c:631` (`-Werror=format-truncation`) ab, und zwar **am sauberen Tip ohne
  jeden Backport** — vorbestehend. Für die Verifikation `-Dwerror=false` verwenden und das im
  PR-Body festhalten, sonst hält man den eigenen Backport für kaputt.
- **Ein Cherry-Pick ist nur dann ein Auswahlvorgang, wenn der Quell-Commit älter ist als die
  Divergenz des Target-Zweigs.** Sonst zieht er unbemerkt Zwischen-Commits mit, die der Zweig
  nie hatte, und der Build bricht. Bei Portierung aus `xorg/main` in alte Releases ist genau das
  der Normalfall, nicht die Ausnahme.
- **Dieselbe Konfliktstelle löst sich pro Zweig semantisch verschieden.** Beispiel
  `drmmode_legacy_cursor_probe_allowed()`: auf 25.2/25.1 als `!probe_allowed` mit early return,
  auf 25.0 als positive Klammer um die Probes. „Merge-Resolution aus master übernehmen" ist
  falsch, „Union bilden und beide Semantiken erhalten" ist die Regel.
- **Ein Vorkommen auf den Release-Zweigen, das master nicht hat, ist eine Divergenz, die in
  keinem Verzeichnis steht.** Sie findet man nur, indem man jeden Zweig einzeln liest.
