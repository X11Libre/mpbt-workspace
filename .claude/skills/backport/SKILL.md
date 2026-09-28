---
name: backport
description: "Router: backports come in two different workflows, load the right one. Use 'backport ours' for our own merged master commits going down to release lines, 'backport xorg/main' for porting new xorg/main commits onto a target branch. Load this when the request is just 'backport' and it is unclear which is meant."
---

# backport — zwei Workflows, nicht einer

„Backport" heißt in diesem Workspace **zwei völlig verschiedene Vorgänge**. Sie haben
unterschiedliche Quellen, unterschiedliche Konfliktbilder, unterschiedliche Nachweise und
unterschiedliche Branch-Regeln. Sie mit einer Prozedur zu behandeln war am 2026-09-28 die
Ursache für zwei zerstörte Fremd-PRs.

| | `backport-ours` | `backport-xorg-main` |
|---|---|---|
| **Quelle** | unsere eigenen Commits aus gemergten master-PRs | `xorg/main` |
| **Problemklasse** | Auswahl — welcher Commit auf welchen Zweig | Integration — fremder Code strukturell einpassen |
| **Ziel** | Release-Zweige | ein Target: master **oder** ein Release |
| **Branch** | **pro Task**, `rfc/backport-<rel>-<task>` | **geteilter Inkubator** `rfc/backport-<target>`, plus Tracker `tracking/xorg/main-on-<target>` |
| **Nachweis** | Commit existiert, Autor, `Signed-off-by` | ob der Zweig die Änderung **inhaltlich** enthält |
| **Konflikte** | meist klein, oft null | pro Zweig verschieden, oft strukturell |
| **Werkzeug** | `starfleetctl github backport applies|commit` | `git rebase`/`--onto` + `scripts/xx-make-pr.sh` |
| **Erfolgsmetrik** | PR je Zweig gemergt | Tracker steht wieder auf `xorg/main` |

## Kurz entscheiden — mechanisch, nicht nach Gefühl

**Autor und Commit-Subject sind kein Kriterium.** Ein xorg/main-Commit kann über unseren
master zu uns gekommen sein, und unsere eigenen Commits tragen dieselben Upstream-Autoren.
Entscheidend ist die Zugehörigkeit zur `xorg/main`-Seite.

```sh
# 1) Ist der Commit überhaupt in xorg/main?
git merge-base --is-ancestor <commit> xorg/main
```

| Ergebnis | meaning | Workflow |
|---|---|---|
| **NEIN** — nicht in `xorg/main` | er ist über unseren master gekommen, also **unser** Commit | `backport-ours` |
| **JA** — in `xorg/main` | weiter prüfen, ob für dieses Target schon bearbeitet | siehe 2) |

```sh
# 2) In xorg/main, aber für dieses Target schon erledigt?
git merge-base --is-ancestor <commit> origin/tracking/xorg/main-on-<target>
```

| Ergebnis | meaning | Workflow |
|---|---|---|
| **JA** — Commit liegt vor dem Tracker | für dieses Target bereits gemergt, in einem offenen PR oder bewusst ausgelassen | **nichts tun** |
| **NEIN** — im Intervall `tracker..xorg/main` | für dieses Target noch nicht übernommen | `backport-xorg-main` |

Belege, die diese Regel stützen:

- `46c411e49b` (PR 3749, die hw-cursor-Sache): **nicht** in `xorg/main`, **ja** in unserem
  master, **nicht** im Tracker-Intervall → `backport-ours`. Genau so wurde es gemacht.
- Die Commits aus den April-Queues mit `[PR #36xx]`-Präfix: von Jeremy Huddleston Sequoia
  **und** von Enrico Weigelt. Trotzdem `backport-xorg-main`, weil das Präfix von
  `xx-make-pr.sh` beim Einreichen geschrieben wird und der Commit aus `xorg/main` stammt.

## Inkubatoren, und wofür es sie gibt

Ein **Inkubator** sammelt immer Commits, die in die **zugehörige target-branch** wandern sollen.
Er ist ein geteilter Arbeitsplatz, kein privastes Repo.

Es gibt mehr als eine Nutzung, und beide kommen in der Praxis vor:

- **xorg/main-Queue** — `rfc/backport-<target>` sammelt die noch nicht übernommenen Commits aus
  dem Intervall `tracking/xorg/main-on-<target>..xorg/main`. Details in `backport-xorg-main`.
- **WIP-Sammelstrecke** — ein Inkubator ist gleichzeitig WIP-Branch. Fertig gewordene Dinge
  werden zwischendurch **isoliert herausgeholt** und als PR eingereicht, während der Rest als
  WIP liegen bleibt.

### Der Lebenszyklus

1. **Regelmäßig auf die target-branch rebasen.** Das ist kein Kosmetik-Schritt: bereits
   gemergte Commits fallen dabei automatisch aus der Queue heraus, und Konflikte gegen die
   target-branch werden sichtbar, bevor jemand darauf aufsetzt.
2. **Einzelne Commits als PR einreichen** über `scripts/xx-make-pr.sh`.
3. **Das Ledger ist der Commit-Subject.** Das Skript schreibt die History des Inkubators um,
   sodass der eingereichte Commit einen Subject-Prefix mit der PR-Id bekommt
   (`[PR #NNNN]`). Daran erkennt man, was bereits submitted wurde — und genau daran verhindert
   man das versehentliche Doppel-Einreichen. Weil umgeschrieben und auf die target-branch
   rebased wird, weichen die SHAs im Inkubator zwangsläufig vom Original ab.

### Wenn das Einreichen blockiert ist

**Das ist normales Verhalten, kein Fehler.** Ist eine weitere Einreichung durch noch
**ungemergte** PRs blockiert, bricht `xx-make-pr.sh` mit **verrückten Konflikten** ab. Diese
Konflikte sind nicht aufzulösen, sondern zu **warten**: bis zum nächsten Rebase auf die
target-branch, und dann erneut probieren, wenn der blockierende PR inzwischen gemerged ist.

Wer's beim ersten Auftreten nicht einordnet, hält es für kaputt und fängt an, Konflikte zu
erzwingen. Wird hier deshalb ausdrücklich genannt.

### Der Clone ist Teil des Verfahrens

`xx-make-pr.sh` liest `make-pr.upstream-remote`, `make-pr.upstream-branch` und
`make-pr.reviewers` aus dem `.git/config` des **aktuellen** Repos. Daran erkennt es, **auf welche
Baseline** der PR-Branch aufzusetzen ist. Wir haben aus gutem Grund getrennte, unterschiedlich
konfigurierte Clones pro target-branch:

| Ziel | Clone |
|---|---|
| `master` | `_WORK_/xserver-master` |
| `release/25.0` | `_WORK_/xserver-25.0` |
| `release/25.1` | `_WORK_/xserver-25.1` |
| `release/25.2` | `_WORK_/xserver-25.2` |

Alles für master passiert im `xserver-master`-Clone, alles für `release/25.0` im
`xserver-25.0`-Clone, und so weiter. Im falschen Clone submitted man gegen die falsche Baseline
und findet es später nicht wieder.

### Auslassungen festhalten: `.backport-skips`

Eine bewusste Auslassung hinterlässt sonst **keine Spur**. Die beiden anderen Zustände sind
strukturell abgesichert — gemergte Commits fallen beim Rebase aus der Queue heraus,
eingereichte tragen den `[PR #NNNN]`-Marker. Der Tracker selbst kann die Auslassung nicht
tragen: er wandert per **Fast-Forward** auf einen `xorg/main`-Commit und übernimmt damit dessen
Commit-Message. Es bleibt technisch kein Platz für einen Verweis.

Deshalb hält der Inkubator eine getrackte Datei **`.backport-skips`**, eine Zeile pro
ausgelassenem Commit: `<sha>  <subject>  — <begründung>`, angehängt pro Lauf, nie überschrieben.

    316321933a  glamor: free the link log on shader link failure  — inhaltlich durch
    482f7b326d (#3750) abgedeckt, ours ist vollstaendiger (calloc-Guard)
    b125b19fc2  xwayland: clean up glamor EGL state on fatal exits  — xwayland entfernt

Sie überlebt den Rebase, reist mit dem Inkubator und liegt dort, wo das nächste Schiff
ohnehin nachsieht. Je Target eine eigene Datei, also keine Merge-Konflikte zwischen Zweigen.

**Der Auslassungsgrund gehört in die Datei, nicht nur in den Task-Log.** Der Task-Log ist
versioniert und bleibt, aber er ist nicht der Ort, an dem jemand beim nächsten Lauf nachsieht.
`_WORK_/` ist aus guten Gründen nicht versioniert und taugt nicht als Ablage.

## Branch-Regel, die für beide gilt

- **Niemals** den nackten `rfc/backport-<rel>` für einen eigenen Task benutzen. Der ist der
  geteilter xorg/main-Inkubator.
- **Vor jedem Force-Push** prüfen, ob der Branch einen offenen PR eines anderen Schiffs trägt.
  Am 2026-09-28 fehlte diese eine Prüfung zweimal: einmal mit 20 fremden Commits, einmal mit
  einem eigenen Backport als Verlust.
- **Vor dem Push sichern, nicht danach.** Alten Tip als `refs/rescue/…` festhalten,
  Wiederherstellung per `--force-with-lease` mit dem erwarteten Wert, danach an Commits **und**
  Dateien verifizieren.

## Merge-Grenze

**Ein Target-Branch wird ausschließlich über gemergte GitHub-PRs weitergeschrieben.** Kein
direktes `git push` und kein Merge des Incubators in den Target, für **keinen** Target —
weder `master` noch `release/*`. Ausnahmen gibt es nur, wenn der Maintainer sie im konkreten
Fall ausdrücklich erteilt.

Das ist keine Formalie, sondern der Mechanismus, auf dem die Queue beruht: **Incubatoren werden
regelmäßig auf den Target rebased, und dabei fallen die bereits gemergten Commits automatisch
aus der Queue heraus.** Das funktioniert nur, wenn der Target über PRs vorankommt. Ein
direkter Merge oder Push umgeht diesen Nachweis, macht den Fortschritt des Trackers unüberprüfbar
und erzeugt beim nächsten Rebase Konflikte und Überraschungen, weil der Target plötzlich
Commits enthält, die nie reviewt wurden.

Konkret heißt das für den Ablauf: Phase I und II pushen auf `rfc/backport-<target>` und
`tracking/xorg/main-on-<target>` — das ist erlaubt. Phase III reicht PRs ein — das ist der
Weg. Ein Push auf `origin/master` oder `origin/release/…` gehört **nicht** dazu und ist ein
Fehler, kein Etappenschritt.

Für **Release**-Merges gilt zusätzlich: manuell, durch den Maintainer. `bot-review-passed` und
grüne CI autorisieren keinen Merge in `release/*`. Auf `master` ist ein Auto-Merge nur bei
ausdrücklicher Bitte des Nutzers zulässig. Nach dem Öffnen der PRs: **stoppen.**

## Und noch etwas, das beide Workflows betrifft

**Ein Merge auf master beweist nicht, dass etwas backport-würdig ist.** Der master-PR kann ein
Refactoring sein, während derselbe Codepfad auf einem Release-Zweig einen NULL-Deref trägt.
Vor jeder Entscheidung gegen den Release-Zweig messen, nicht aus dem master-PR schließen.
