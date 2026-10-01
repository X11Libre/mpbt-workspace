# xserver PR workflow — submit via xx-make-pr

Submitting xserver (and driver) PRs goes through `starfleetctl xx-make-pr`,
**never** through a hand-typed `gh pr create`. The tooling does everything a
proper PR needs in one step; a manual `gh pr create` silently misses parts.

## When to use

Use this skill when you need to create a PR for the xserver or a driver
within the mpbt-workspace, ensuring the PR includes the required assignee,
reviewer team, and proper title formatting. Also use it to clean up CI runs
left behind by deleted branches — see "Aufräumen: CI-Runs gelöschter Branches"
(`starfleetctl github ci prune`).

## How to use

1. Commit your changes on a branch inside the appropriate clone
   (e.g. `_WORK_/xserver-master/sources/xlibre/xserver`).
2. Run, **from inside the clone**:

   ```bash
   /path/to/starfleetctl xx-make-pr <sha>
   ```

   where `<sha>` is the commit you want to submit.

## What the skill does

- Creates the PR branch from the configured upstream (`origin/master`),
  cherry-picks your commits, strips any incubator `[PR #N] ` subject prefix.
- Pushes the branch.
- Creates the PR with:
  - **assignee** `@me` (`-a @me`)
  - **reviewer team** from `make-pr.reviewers` (`--reviewer X11Libre/dev`)
  - title `(master) <commit subject>`
- Afterwards marks the incubator copies of the submitted commits with a
  `[PR #N] ` subject prefix + `PR: <url>` trailer (via a scripted
  `GIT_SEQUENCE_EDITOR`).

## Configuration

The clone’s `.git/config` already contains:

```
make-pr.upstream-remote = origin
make-pr.upstream-branch = master
make-pr.reviewers       = X11Libre/dev
```

## Manual `gh pr create` pitfalls

A PR created by hand has **no assignee and no reviewer team** — the fleet’s
review workflow depends on the `X11Libre/dev` team being requested. If a PR
was already created manually, repair it:

```bash
gh api --method POST repos/X11Libre/xserver/issues/<n>/assignees \
    -f 'assignees[]=metux'
gh api --method POST repos/X11Libre/xserver/pulls/<n>/requested_reviewers \
    -f 'team_reviewers[]=dev'        # team slug, not "X11Libre/dev"
```

## After opening the PR

- Run the **bot-review** flow (skill `bot-review`): post the verdict comment
  with the bot banner and apply `bot-review-passed` /
  `bot-review-changes-requested`.
- Merges into `release/*` are **manual-only, by the maintainer** — never
  auto-merge a release-line PR, regardless of CI or review status.

## Aufräumen: CI-Runs gelöschter Branches

Wir arbeiten mit sehr vielen kurzlebigen Branches — PR-Automatik-Branches und
WIP-Branches, die oft neu gebaut werden. Jeder davon hinterlässt Runs in der
Workflow-Liste. Ist der Branch auf GitHub gelöscht, sind die Runs wertlos.

Das ist **keine eigene Funktion**, sondern `starfleetctl github ci prune`, das
GONE-Runs bereits löscht. Kein Code nötig, nur der Aufruf.

```bash
# 1. Dry run — zeigt stale + gone, löscht nichts (Default)
starfleetctl github ci prune --verbose

# 2. Nur Branch-Leichen, aktive Branches unangetastet
starfleetctl github ci prune --verbose | grep '^GONE'

# 3. Erst dann löschen (irreversibel)
starfleetctl github ci prune --delete
```

**Was `ci prune` klassifiziert** (`internal/ghpr/prunestaleci.go`):

| Klasse | Bedeutung | Aktion |
|---|---|---|
| `GONE` | Branch liefert 404 | gelöscht |
| `STALE` | Branch existiert, Tip ≠ Run-SHA | gelöscht |
| `KEEP` | Branch existiert, Tip == Run-SHA | bleibt |

**Sicherheitslinie:** gelöscht wird ausschließlich, wo `resolveBranchTip()` den
Branch nicht auflösen kann. Für PR-Runs aus Forks prüft die Funktion den Branch
im **Head-Repo** (`HeadRepo.FullName`), nicht in unserem — ein Fork-PR wird also
nicht fälschlich als „gone" eingestuft.

**Optionen:**

- `--branch <name>` / `--workflow <name>` — auf einen Branch oder Workflow
  eingrenzen
- `--keep-gone` — GONE **behalten** (Gegenstück; ohne die Flag werden GONE
  gelöscht)
- `--delete` — ohne die Flag ist alles Dry-Run

**Grenzen, die man kennen muss:**

- Nur `status=completed`. Ein **laufender** Run auf einem gelöschten Branch bleibt
  stehen und wird nie gelöscht.
- Nur gegen `origin`-Repos des Workspace — `STARFLEET_GITHUB_REPO` beachten.
- **Branches nicht löschen, um Runs loszuwerden.** Ein gelöschter Branch nimmt
  seinen PR-Checkstatus mit; das ist bei `--delete` nicht reversibel.

**Typischer Fehler im Ablauf:** Ein PR-Branch wird nach dem Merge gelöscht,
während wir noch auf dessen grüne CI warten. Dann ist der Beleg weg — genau das
ist am 2026-09-30 mit PR #3768 passiert (Runs nach dem Merge nicht mehr
abrufbar, `404`). **Vor dem Löschen des Branches den Run-Status kopieren.**



## `tmp-pr` darf nie als Branchname entstehen — Git-Ref-Kollision

`make-pr` bzw. `xx-make-pr` legt zum Cherry-Picken erst einen ** temporäreren** Branch an
(`internal/ghpr/xxmakepr.go:98, 109`):

```go
tmpBranch := "tmp-" + branchName           // branchName ist z.B. "pr/master-<slug>_<zeitstempel>"
git checkout -b tmpBranch upstreamRef
```

Bei einem automatisch erzeugten `branchName` heißt der temporäre Branch also
**`tmp-pr/master-<slug>_<zeitstempel>`**.

**Die Falle:** existiert zusätzlich ein Branch, der exakt `tmp-pr` heißt, ist
`refs/heads/tmp-pr` bereits als Ref belegt. Git kann dann **keinen** Ref unter
`refs/heads/tmp-pr/...` anlegen — Verzeichnis-vs-Datei-Konflikt in den Refs.
Nachgemessen:

```console
$ git branch tmp-pr
$ git checkout -b tmp-pr/master-foo_x
fatal: cannot lock ref 'refs/heads/tmp-pr/master-foo_x': 'refs/heads/tmp-pr' exists;
       cannot create 'refs/heads/tmp-pr/master-foo_x'
```

Das sieht nach einem Git-Problem aus, ist aber ein **Namensraumproblem**, und die Fehlermeldung
nennt den Auslöser nicht. `make-pr` bricht dann kommentarlos ab und alle weiteren
`tmp-pr/*`-Branches fallen ebenfalls aus.

**Regel:** niemals einen Branch namens `tmp-pr` anlegen, und wenn er auftaucht, sofort
löschen — er ist reine Altlast und blockiert das gesamte make-pr-Verfahren:

```bash
git branch -D tmp-pr          # lokal
git push origin --delete tmp-pr   # falls er auf origin liegt
```

Der Präfix `tmp-` ist für die make-pr-Mechanik reserviert. Eigene Staging-Branches
brauchen einen anderen Präfix, z. B. `wip/`.

### Altlast `tmp-pr-1` — das ist kein `tmp-pr`, aber ein Symptom

`tmp-pr-1` blockiert `tmp-pr/*` **nicht** (anderer Refname), ist aber fast immer das
Ergebnis eines abgebrochenen make-pr-Laufs. Stand 2026-09-30 existiert `tmp-pr-1` in
mehreren Clones und war im Worktree `xorg-main-master` sogar **ausgecheckt** (`*tmp-pr-1`),
was zwischen zwei Schiffen zu Kollisionen führte.

**Warum die Branches überhaupt liegen bleiben:** `xx-make-pr` räumt auf **keinem** seiner
sechs Fehlerpfade auf (kein `defer`, kein `branch -D`) — bricht der Cherry-Pick ab, bleibt
der `tmp-`-Branch im Clone liegen. Gepusht wird er zwar nie (nur `branchName`, Zeile 133),
die Altlast auf `origin` stammt also aus einer älteren Tool-Version oder von Hand.

Vor einem make-pr-Lauf also prüfen und aufräumen:

```bash
git branch --list 'tmp-*'        # lokale Reste
git branch -r --list 'origin/tmp-*'   # Altlast auf origin
```

**Ein abgebrochener make-pr-Lauf darf nie im Agenten-Schiff liegen bleiben.** `xx-make-pr`
lässt im Fehlerfall einen halben Cherry-Pick im Clone zurück, und jeder weitere Aufruf
arbeitet dann auf diesem Zustand weiter.
