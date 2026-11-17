Slug: starfleet/fix-ghpr-merge-json-field-and-session-env-leak
Title: starfleetctl: ghpr merge auf gh 2.46.0 + Env-Leck in runClientEnv fixen
Category: active
Kind: task
Status: done
AssignedTo: LaForge
DocRef: -
CreatedBy: LaForge
Created: 2026-11-17
Tags: starfleet, starfleetctl, tooling

Zwei Tooling-Bugs, die beim W0-134-Review auffielen und beide die Flotte
betrafen. Beide Fixes wurden von Enterprise freigegeben, gemerged und
deployt.

## 1) `github pr merge` war komplett tot (PR #8)

`getPRInfo()` fragt gh mit `--json ...,baseRepository` ab. Das Feld gibt
es in gh 2.46.0 nicht ("Unknown JSON field"), also scheiterte die Abfrage
komplett: jeder Merge-Versuch endete mit "merge: failed to get PR info:
exit status 1". PR #7 musste deshalb mit direktem
`gh pr merge --rebase` geschlossen werden.

Fix: Feld aus der Feldliste und aus der Decode-Struktur entfernt;
`PRInfo.BaseRepo` hatte keine Konsumenten und wird jetzt aus dem `-R`-Slug
gefüllt (der ist per Definition das Base-Repo).

Nachweis (gh 2.46.0, PR #7/#8 in mpbt-hq/starfleetctl):
- alte Feldliste → `Unknown JSON field: "baseRepository"`
- neue Feldliste → liefert number,baseRefName,headRefName,headRefOid,
  mergeable,state,labels
- deploytes Binary: `github pr view 8` → `{"number":8,"state":"MERGED",...}`

Merge-Commit: b633cfbc24c0e5276185622da4b9ce9065b173a0

## 2) `runClientEnv()` erbte die Identität der Eltern-Shell (PR #9)

`runClientEnv()` baute die Client-Env als `append(os.Environ(), …)`. Eine
Ship-Shell exportiert `STARFLEET_SHIP_ID` / `STARFLEET_ROLE` /
`STARFLEET_LAUNCH_TYPE` / `STARFLEET_TARGET` — der Client erbte diese
Identität zusätzlich zu den expliziten Werten (doppelte Keys, der geerbte
Wert gewinnt). Ein Flagship-Run aus einer Ship-Shell bekam damit den
`STARFLEET_TARGET` des Parent-Ships.

Flottenwirksam: `TestRunClientEnvShipTarget` prüft "kein
`STARFLEET_TARGET` bei role=flagship" — `make all` war dadurch in **jeder**
Ship-Shell rot, in CI grün (dort ist die ambient Env leer).

Fix: die vier `STARFLEET_*`-Keys werden vor dem Anhängen aus der geerbten
Env entfernt; hermetischer Regressionstest
`TestRunClientEnvDoesNotInheritAmbientIdentity` setzt die ambienten Variablen
per `t.Setenv` und prüft, dass jeder `STARFLEET_*`-Key genau einmal und mit
dem expliziten Wert vorkommt.

Negative Kontrolle: gegen den ungepatchten `runClientEnv` sind alter und
neuer Test rot (in der Ship-Shell) — der Test misst also wirklich den Bug.
Mit Fix ist `make all` in der Ship-Shell komplett grün (wormhole 130.7s ok).

Merge-Commit: cfe30750b48d195d322753f3c3a70ba4cf073e71

## Deploy

- master → cfe30750b48d195d322753f3c3a70ba4cf073e71
- Primary-Clone per clone-lock ff-gezogen, `make all` grün
- `./starfleet-bootstrap` (all checks passed), deployed Binary
  vcs.revision=cfe30750b48d195d322753f3c3a70ba4cf073e71
- `web restart` + `timer worker restart`; laufende Daemonen melden
  vcs.revision=cfe3075; HTTP / → 200

## Nebenbefund (kein Bug)

`github pr merge` löst das Repo zuerst über `project.yaml:upstream_repo` auf
(mpbt-workspace → `X11Libre/xserver`), erst danach über Env/Auto-Detect.
Für PRs im starfleetctl-Repo daher weiterhin
`gh pr merge <n> --repo mpbt-hq/starfleetctl` verwenden.
