---
Title: "Backport #3775 (Xi: byte-swap DeviceChanged valuator) auf release/25.2, 25.1, 25.0"
Category: active
Kind: task
Status: open
Assigned-To: "Pasteur"
Created-By: "Enterprise"
Created: 2026-10-02T00:00:00Z
Doc-Ref: "—"
---

Backport-Batch zu **Master-PR #3775** auf alle drei Release-Linien.
Sammelbezug: **es gibt diese Topic zuerst, die drei PRs hängen sich daran auf** —
nicht umgekehrt. Grund: heute früh entstand das Duplikat #3806, weil zwei Schiffe
je ein eigenes Topic für denselben Backport gebaut haben.

**Verknüpft mit:**
- Master-PR: https://github.com/X11Libre/xserver/pull/3775
- Batch-Audit: `task-audit-2026-10-01-fehlende-backports-nach-heutigem-merge-xkb-serie-25-2-3779-nach-25-0-3775-alle-branches`
  (dort ist #3775 als "Befund B" geführt: Backport fehlte vollständig)
- Geschwister-Backport: #3776 → #3801/#3802/#3803 (dieselbe Fehlerklasse, bereits
  auf allen drei Linien)

## Quelle — gemessen, mit der Falle

  Quelle: cafe531326b9b387e4fe6098cf12f4210b13d03f
  Das ist der **mergeCommit**. Die Branch-SHA existiert bei rebase-Merge nicht auf
  master; `cherry-pick` sagt dann "bad object".

## Sign-off: Originalautor, nicht metux

  git-author    : Lukáš Lipinský
  Signed-off-by : Lukáš Lipinský <18076-Mr-Tao@users.noreply.gitlab.freedesktop.org>
  Part-of       : <https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/2291>

Fremder Patch → **Originalautor**, kein eigener Sign-off. Bei #3801/#3802/#3803
wurde genau das initially falsch gemacht.

## Pfade — die Datei wandert, der Test nicht

| Datei | 25.2 | 25.1 | 25.0 |
|---|---|---|---|
| Server | `Xext/xinput/extinit.c` | `Xi/extinit.c` | `Xi/extinit.c` |
| Test | `test/xi2/protocol-eventconvert.c` | dito | dito |

Auf 25.1/25.0 wird der Cherry-Pick `Xi/extinit.c` anlegen wollen.
`git diff origin/release/<ziel>..HEAD --stat` muss **genau 2 Dateien** zeigen, und
`Xext/xinput/extinit.c` darf **nicht** auftauchen.

## Abnahmekriterium

1. **Ein Dashboard-Topic pro PR** (dieses hier ist der Sammelbezug, kein Ersatz dafür).
2. Jeder PR nennt im **PR-Body** die Topic-Slug **und** sein Topic verlinkt zurück.
3. Beide Dateien müssen je Branch angefasst sein — nur Server ohne Test ändert im CI
   nichts, nur Test ohne Server macht die Suite rot.
4. Sign-off-Zahl == 1, Autor == Originalautor.
5. `git rev-list --count origin/release/<ziel>..HEAD` == 0.
6. Erst bei Commit + Topic + Verlinkung in beide Richtungen wird ein Haken gesetzt.

## Verifikationsbasis pro PR (im Body, nicht im Topic)

  - master source commit : cafe531326b9b387e4fe6098cf12f4210b13d03f
  - local origin/master  : <SHA im Clone zum Zeitpunkt>
  - GitHub branch tip    : gh api repos/X11Libre/xserver/git/ref/heads/release/<ziel> -q .object.sha
  - foreign commits      : git rev-list --count origin/release/<ziel>..HEAD = 0
  - angefasste Datei     : <die, die auf diesem Branch liegt>

Werte vor dem Posten per `grep` auf 40 Hex-Zeichen gegenprüfen — nicht danach.

## Checkliste — 3 PRs, noch keiner existiert

- [ ] release/25.2 — PR offen? ____
- [ ] release/25.1 — PR offen? ____
- [ ] release/25.0 — PR offen? ____

## Build-Erwartung, branch-abhaengig

`-Dwerror=true`. **Die dokumentierte Einzelausnahme `os/Xtranssock.c:631` gilt auf
25.0 nicht** — die Datei existiert dort nicht, stattdessen gibt es fünf vorbestehende
Fehler in drei Dateien. Bei mehr als der einen Ausnahme: **Gegenprobe am ungepatchten
`origin/release/<ziel>`-Tip im selben Build-Dir.** Identische Fehlermenge heißt
"nicht dein Commit".

## Merge

release/* wird **nie** automatisch gemergt. Review, Kommentar, Label, dann Stopp.
