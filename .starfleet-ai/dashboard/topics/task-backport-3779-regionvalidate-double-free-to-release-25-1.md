---
Title: "Backport #3779: RegionValidate double free of badreg->data auf release/25.1"
Category: active
Kind: task
Status: "open"
Created-By: "Barcley"
Created: "2026-10-01T17:20:00Z"
Assigned-To: "Barcley"
Doc-Ref: "https://github.com/X11Libre/xserver/pull/3794"
Slug: task-backport-3779-regionvalidate-double-free-to-release-25-1
---

Backport **#3779** auf **release/25.1**. Ein PR, ein Branch, ein Topic — Teil des
Batches `task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0`.

## Abnahme-Daten des Maintainers

| Feld | Wert |
|---|---|
| **PR-Nummer** | [#3794](https://github.com/X11Libre/xserver/pull/3794) |
| **Commit-SHA des Backports** | `9dfb86c2ea8e46c3c5839ac4008763a03f897044` |
| **Source-Commit auf master** | `e84a8065c4f33178bbc687fa0a67511fb9eb4165` |
| **Zielbranch** | `release/25.1` |
| **Backport-Branch** | `rfc/backport-25.1-region-double-free` |
| Datei | `dix/region.c` (1 Datei, +5) |
| Topic-Slug (dieses) | `task-backport-3779-regionvalidate-double-free-to-release-25-1` |
| PR verlinkt dieses Topic | ja, im PR-Body (Abschnitt "Dashboard") |

## Inhalt

`RegionValidate()` kopiert `*badreg` nach `ri[0].reg`, wodurch `ri[0].reg.data` und
`badreg->data` auf denselben Block zeigen. Ein spaeteres `RECTALLOC_BAIL()` kann
diesen Block per `realloc()` verschieben: `ri[0].reg.data` wird aktualisiert,
`badreg->data` nicht. Auf dem Bail-Pfad gibt `xfreeData(&ri[i].reg)` den Speicher
frei, `RegionBreak(badreg)` gibt `badreg->data` ein zweites Mal frei — stale Pointer
auf freigegebenen oder umallozierten Speicher. **Doppel-Frei.**

Fix ist eine Zeile: `badreg->data = NULL;` vor `return RegionBreak(badreg)`.

Client-erreichbar (`RegionValidate()` laeuft auf Client-Regions via XFixes/XComposite),
Memory-Safety — damit eindeutig backport-wuerdig.

## Source-SHA: die gelieferte war falsch, der Inhalt nicht

Die Direktive nannte `e02f90995bfc`. Diese SHA liegt **nicht** auf `origin/master`,
sondern nur auf dem make-PR-Branch-Tip
`origin/pr/master-regionvalidate-...-2026-10-01_15-16-20`. Bei rebase-Merge — am
xserver verpflichtend — bekommt der master-Commit eine eigene SHA.

    git merge-base --is-ancestor e02f90995bfc origin/master   ->  NEIN
    git merge-base --is-ancestor e84a8065c4  origin/master   ->  JA

Getrennt wurde "Beschriftung falsch" von "Inhalt falsch" ueber den **Patch-Vergleich**,
nicht ueber den Subject:

    git diff e84a8065c4^  e84a8065c4  -- dix/region.c
    git diff e02f90995bfc^ e02f90995bfc -- dix/region.c
    -> identisch (leerer Diff)

Ursache laut Enterprise (m125588): die SHAs wurden aus `gh pr view --json .commits`
gelesen — das sind die Commits des PR-**Branches**, nicht der gemergte master-Commit.
Korrekte SHAs sind seither an Galaxy und Scotty raus (m125584/m125585).

## Branch-Herkunft — der geteilte Inkubator

`starfleetctl github pr mk-agent-clone 25.1 <name>` legt den Agent-Clone auf dem
**nackten** `rfc/backport-25.1` an und trackt `origin/rfc/backport-25.1`. Das ist der
geteilte xorg/main-Inkubator, nicht der Task-Branch:

    git rev-list --left-right --count origin/release/25.1...origin/rfc/backport-25.1
    -> 2  6

6 Commits, die nicht in `release/25.1` sind. Der Zustand sieht plausibel aus —
Branch existiert, HEAD ist sauber, cherry-pick laeuft — also ist er nicht als Fehler
erkennbar und schleppt die 6 Commits in den Release-PR.

Die Groesse unterscheidelt sich pro Release: auf 25.2 sind es **32**, auf 25.1 nur 6.
Die Falle ist ueberall dieselbe, die Zahl nicht. Wer auf 25.1 nach "32 Commits"
sucht, findet nichts und haelt die Falle fuer harmlos.

Korrigiert: `git checkout -b rfc/backport-25.1-region-double-free origin/release/25.1`
(c961c43cec). Kontrolle: `git rev-list --count origin/release/25.1..HEAD` = **0** vor
dem Cherry-Pick, **1** danach.

## Build-Verifikation

`meson setup -Dwerror=true -Dxephyr=true -Dxnest=true -Dxvfb=true -Dxorg=true`, dann
`ninja -k 0` — bewusst mit `-k 0`, damit **alle** 710 Targets gebaut werden und die
Fehlermenge vollstaendig ist, statt nur dem ersten Fehler zu folgen.

Genau ein Fehler, die eine dokumentierte vorbestehende Ausnahme:

    os/Xtranssock.c:631  -Werror=format-truncation

Gegenprobe am **unpatchten** Tip `c961c43cec` im selben Build-Dir: identische
Fehlermenge, identisches FAILED-Target `os/libxserver_os.a.p/transport.c.o`. Der
Backport fuegt also nichts hinzu.

Nicht `-Dwerror=false`: das schaltet genau den Mechanismus ab, mit dem die
Release-Lanes toten Code finden (siehe `backport-ours`, Schritt 3).

## Trailer

Genau ein Commit, cherry-pickt mit `-x`. `Part-of:` zeigt auf den **xorg-Ursprung**
MR 2281, nicht auf unseren PR — nach aussen, das Gegenteil des `[PR #NNNN]`-Markers.
Kein `[PR #NNNN]`-Marker im Commit, weil es ein Port eines xorg-Commits ist.

## Merge

**Nicht** gemergt. `release/*` wird vom Maintainer von Hand gemergt, Merge-Mode
`rebase`. Dieser PR steht auf Review, kein `bot-review-passed` angefordert.
