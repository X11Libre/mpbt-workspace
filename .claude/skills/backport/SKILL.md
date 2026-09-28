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
