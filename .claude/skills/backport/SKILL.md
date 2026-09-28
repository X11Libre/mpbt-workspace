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

## Kurz entscheiden

- **Der Commit ist ours** (Autor Enrico Weigelt / X11Libre, aus einem unserer master-PRs) →
  `backport-ours`.
- **Der Commit ist von xorg/main**, auch wenn Jeremy Huddleston Sequoia oder ein anderer
  Upstream-Autor ihn geschrieben hat → `backport-xorg-main`. Upstream-Autor heißt nicht
  xorg/main-Übernahme; entscheidend ist, ob der Commit über unseren master kam oder direkt von
  `xorg/main` stammt.
- **Ein master-PR `[PR #36xx]` im Subject** im Inkubator → das ist der Marker, den
  `xx-make-pr.sh` beim Einreichen setzt. Der Commit *stammt* von `xorg/main`, nicht von unserem
  master-PR. `backport-xorg-main`.
- **Ein commit ohne `xwayland`-Anteil, der im Tracker-Intervall liegt** → `backport-xorg-main`.
- **Ein Fix, den wir selbst geschrieben haben** → `backport-ours`, und zwar **zuerst** der Fix
  auf master, **dann** der Backport. Sonst wandert der Fehler mit in die Releases.

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

**Release-Merges sind manuell, durch den Maintainer.** `bot-review-passed` und grüne CI
autorisieren keinen Merge in `release/*`. Auf `master` ist ein Auto-Merge nur bei expliziter
Bitte des Nutzers zulässig. Nach dem Öffnen der PRs: **stoppen.**

## Und noch etwas, das beide Workflows betrifft

**Ein Merge auf master beweist nicht, dass etwas backport-würdig ist.** Der master-PR kann ein
Refactoring sein, während derselbe Codepfad auf einem Release-Zweig einen NULL-Deref trägt.
Vor jeder Entscheidung gegen den Release-Zweig messen, nicht aus dem master-PR schließen.
