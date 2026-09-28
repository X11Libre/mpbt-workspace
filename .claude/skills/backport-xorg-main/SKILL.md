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
   xorg-Testskripte, die in ältere Releases nicht übernommen werden. Auslassungen gehören
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

**Bricht das Skript mit verrückten Konflikten ab, ist das eine Blockierung durch noch
ungemergte PRs, keine kaputte Basis.** Nicht auflösen, sondern liegen lassen, bis zum nächsten
Rebase auf die target-branch neu versuchen — in der Regel ist der blockierende PR dann gemerged.
Wer das nicht kennt, erzwingt Konflikte und macht aus einer Warteschleife eine Scheinlösung.

## Was nicht mehr dazugehört

Eigene Commits aus unseren master-PRs in den Incubator zu legen war früher üblich und ist
**Auslaufmodell**, weil wir inzwischen PR-Dashboards haben. Für eigene Commits gilt
`backport-ours` mit einem eigenen Branch pro Task.

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
