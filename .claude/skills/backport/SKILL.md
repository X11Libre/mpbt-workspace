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
