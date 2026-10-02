---
Title: "Backport #3779: RegionValidate double free of badreg->data auf release/25.0"
Category: active
Kind: task
Status: "open"
Created-By: "Barcley"
Created: "2026-10-01T17:20:00Z"
Assigned-To: "Barcley"
Doc-Ref: "https://github.com/X11Libre/xserver/pull/3805"
Slug: task-backport-3779-regionvalidate-double-free-to-release-25-0
---

Backport **#3779** auf **release/25.0**. Ein PR, ein Branch, ein Topic — Teil des
Batches `task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0`.

## Abnahme-Daten des Maintainers

| Feld | Wert |
|---|---|
| **PR-Nummer** | [#3805](https://github.com/X11Libre/xserver/pull/3805) |
| **Commit-SHA des Backports** | `32fa95c3c34e24225e8b2a35da47177824ce7375` |
| **Source-Commit auf master** | `e84a8065c4f33178bbc687fa0a67511fb9eb4165` |
| **Zielbranch** | `release/25.0` |
| **Backport-Branch** | `rfc/backport-25.0-region-double-free` |
| Datei | `dix/region.c` (1 Datei, +5) |
| Topic-Slug (dieses) | `task-backport-3779-regionvalidate-double-free-to-release-25-0` |
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

## Branch-Herkunft — auf 25.0 zwei Werkzeugprobleme

Auf 25.2/25.1 legt `starfleetctl github pr mk-agent-clone <rel> <name>` den
Agent-Clone auf dem **nackten** `rfc/backport-<rel>` an — dem geteilten
xorg/main-Inkubator. Gemessen: 25.2 `9  32`, 25.1 `2  6`, 25.0 `4  6`. Der Zustand
sieht plausibel aus (Branch existiert, HEAD ist sauber, cherry-pick laeuft), also
ist er nicht als Fehler erkennbar.

**Auf 25.0 kommt ein zweites Problem davor:** `mk-agent-clone 25.0` schlug fehl.

    mk-agent-clone: reference clone not found:
      _WORK_/generic-25.0/sources/{project}

Das Werkzeug sucht `generic-25.0`, das Repo liegt unter `_WORK_/xserver-25.0`. Der
Release-Name 25.0 ist offenbar keinem Solution-Namen zugeordnet.

Ersatzweise ueber das ebenfalls sanktionierte `starfleetctl worktree add` mit
explizitem Repo-Pfad gearbeitet:

    starfleetctl worktree add _WORK_/xserver-25.0/sources/xlibre/xserver region-double-free
    -> _WORK_/worktrees/xserver/region-double-free, Branch wt/region-double-free

**Achtung fuer Reviewer:** die Referenz dort war **veraltet** — 1 Commit hinter
`origin/release/25.0`, 0 Commits Fremdinhalt. Deshalb wurde der Arbeitsbranch
nicht vom Worktree-HEAD abgezweigt, sondern vom Remote:

    git checkout -b rfc/backport-25.0-region-double-free origin/release/25.0   # d9f34d33eb
    git rev-list --count origin/release/25.0..HEAD   ->  0 vor dem Cherry-Pick, 1 danach

Ein Worktree statt eines Agent-Clones ist an diesem PR deshalb nichts Besonderes.

## 25.0-Form ist nicht identisch mit 25.1/25.2 — der Patch-Kontext unterschied sich

`RegionValidate()` auf 25.0 kennt `sizeRI = 4;` statt
`RegionInfo *ri = calloc(4, sizeof(RegionInfo));`, und die Bail-Schleife lautet
`for (i = 0; i < numRI; i++)` statt `for (int i = 0; i < numRI; i++)`.

Der Cherry-pick lief trotzdem durch — der Kontext passte ueber den 3-Wege-Merge.
Nachkontrolliert statt angenommen: die **hinzugefuegten Zeilen** (`+`-Zeilen des
Diffs) sind byteweise identisch mit denen des master-Patches.

    git diff HEAD^ HEAD -- dix/region.c | grep '^+[^+]'   vs   master-Patch | grep '^+[^+]'
    -> identisch

Unterschiede im Gesamtdiff sind nur Blob-Hashes, Hunk-Zeilennummer (1312 statt
1315) und die Kontextzeile `for (i` statt `for (int i` — letztere ist **vorbestehender
Code des Zweigs**, nicht Teil der Aenderung.

## Build-Verifikation

## 25.0 hat KEINE Einzelausnahme — vier vorbestehende Fehler

Auf 25.2/25.1 ist genau **eine** Warnung mit `-Dwerror` erlaubt,
`os/Xtranssock.c:631 -Werror=format-truncation`. **Auf 25.0 gilt diese Ausnahme
nicht.** Dort gibt es vier vorbestehende Fehler in drei Dateien, die mein Commit
nicht anfasst:

| Datei | Warnung |
|---|---|
| `glx/glxcmds.c` | `argument 1 range [...] exceeds maximum object size` (`-Werror=alloc-size-larger-than=`) |
| `glx/unpack.h:126` | `unused variable 'swapPC'` (`-Werror=unused-variable`) |
| `glx/unpack.h:127` | `unused variable 'swapEnd'` (`-Werror=unused-variable`) |
| `os/connection.c` | `'strncpy' output truncated before terminating nul` (`-Werror=stringop-truncation`) |
| `os/xstrans.c` | `unused variable` (`-Werror=unused-variable`) |

FAILED-Targets: `glx/libxserver_glx.a.p/glxcmds.c.o`,
`os/libxserver_os.a.p/connection.c.o`, `os/libxserver_os.a.p/xstrans.c.o`.

`os/Xtranssock.c:631` taucht auf 25.0 **nicht** auf — weil die Datei in diesem Baum
nicht existiert:

    git ls-files | grep -E 'transport\.c$|Xtranssock'    ->  leer

`os/transport.c` und `os/Xtranssock.c` gibt es auf 25.0 nicht, und im 25.0-Build-Log
kommen sie mit **0** Treffern vor (auf 25.1: 4). Die dokumentierte Einzelausnahme
beschreibt also 25.1/25.2, nicht 25.0.

Gegenprobe am **unpatchten** Tip `d9f34d33eb`, selbes Build-Dir, gleiches `ninja -k 0`:
**identische** Fehlermenge, identische FAILED-Targets. Der Backport fuegt nichts
hinzu.

Compiler: `gcc (Debian 14.2.0-19) 14.2.0`. Die lokalen `-Werror`-Fehler muessen nicht
die der CI sein — die Lanes bauen teils mit clang und anderen Versionen, und genau
darum ist die Gegenprobe das Argument und nicht die Fehlerzahl. **Der Merge
entscheidet das, nicht dieser PR.**

Nicht `-Dwerror=false`: das schaltet genau den Mechanismus ab, mit dem die
Release-Lanes toten Code finden (siehe `backport-ours`, Schritt 3).

## Trailer

Genau ein Commit, cherry-pickt mit `-x`. `Part-of:` zeigt auf den **xorg-Ursprung**
MR 2281, nicht auf unseren PR — nach aussen, das Gegenteil des `[PR #NNNN]`-Markers.
Kein `[PR #NNNN]`-Marker im Commit, weil es ein Port eines xorg-Commits ist.

## Merge

**Nicht** gemergt. `release/*` wird vom Maintainer von Hand gemergt, Merge-Mode
`rebase`. Dieser PR steht auf Review, kein `bot-review-passed` angefordert.
