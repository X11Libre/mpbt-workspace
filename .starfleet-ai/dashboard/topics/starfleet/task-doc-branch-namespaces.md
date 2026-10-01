Title: "User-Doku: Branch-Namensraeume und tmp-Staging-Branch dokumentieren"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Laforge"
Created-By: "Voyager"
Created: "2026-10-01T11:37:52Z"
Doc-Ref: "—"

Vom Maintainer angefordert: die Branch-Konventionen gehoeren in die User-Dokumentation, nicht nur in SOP und Skills. Im Workspace-README ist es jetzt drin (5cd8e666be), aber doc/ des starfleetctl-Repos kennt die Konvention an keiner Stelle — verifiziert: grep nach namespace|reserviert|prefix|prefixe|pr/|wt/ in doc/USER.md liefert null Treffer.\n\nLÜCKE 1 — doc/USER.md Abschnitt 4.10 'Worktrees (Isolated Checkouts)', Zeile 302.\nDort stehen 'worktree add / list / remove'. Es steht NICHT, dass der Befehl den Branch\nwt/<name> selbst erzeugt (internal/worktree/run.go:129: git worktree add -b 'wt/'+name)\nund dass remove/prune Branch UND Pfad gemeinsam aufraeumen. Wer das nicht weiss, legt\nwt/-Branches von Hand an und hat dann zwei Orte fuer einen Worktree.\n\nLÜCKE 2 — doc/github.md Abschnitt '### xx-make-pr', Zeile 131.\nDort steht nur die Syntax. Es steht NICHT, welchen temporaeren Branch der Befehl anlegt.\nDas ist genau die Stelle, an der jemand auf die Idee kommt, selbst 'tmp-pr' zu bauen.\nFestzuhalten:\n  - der Staging-Branch ist 'tmp-' + branchName (internal/ghpr/xxmakepr.go:98,109),\n    bei auto-generiertem branchName also tmp-pr/<upstream>-<slug>_<zeitstempel>\n  - vor dem Push wird er per 'git branch -M' auf pr/... umbenannt (Zeile 131)\n  - gepusht wird nur branchName, der tmp-Branch nie (Zeile 138)\n  - es wird auf KEINEM der sechs Fehlerpfade aufgeraeumt — das ist BEABSICHTIGT, damit\n    ein abgebrochener Cherry-Pick von Hand fertiggestellt werden kann. Als Kommentar\n    festhalten, sonst baut es der naechste wieder ab.\n\nLÜCKE 3 — neue, kleine Sektion in doc/USER.md (oder github.md): Branch-Namespaces.\nTabelle wie im README: wt/ = worktree add, pr/ = github pr make,\ntmp-pr/ = github pr make (Staging). Alles andere frei: rfc/, fix/, submit/, wip/.\nMit der Warnung und der Reproduktion:\n  git branch tmp-pr\n  git checkout -b tmp-pr/master-foo_x\n  fatal: cannot lock ref 'refs/heads/tmp-pr/master-foo_x': 'refs/heads/tmp-pr' exists\nund dem Hinweis, dass tmp-pr-1 NICHT blockiert, sondern die Spur eines abgebrochenen\nLaufs ist.\n\nWARTE-MAL, Richlinie: das ist USER-Dokumentation fuer Menschen, nicht SOP fuer Agents.\nDie Agenten-Seite (Arbeitsregeln, Pflicht zur Nutzung von worktree add statt git worktree,\n'niemals im geteilten Clone schreiben') ist damit NICHT aufzufangen — die gehoert in\nfragments/starfleet-skills/starfleet-sessions und laeuft bereits als eigener Auftrag.\nHier geht es nur um: welcher Branchname gehoert wem, und warum.\n\nGRUNDLAGEN (gemessen, nicht geraten):\n  - make-pr-Historie: TMP_BRANCH war NIE fest auf 'tmp-pr' verdrahtet, auch nicht in der\n    ersten Fassung a8df6d31b9 vom 2026-04-15. Ein exaktes tmp-pr entsteht nur durch\n    '--branch pr' oder von Hand.\n  - die Kollision ist in Git nachgestellt und reproduziert, nicht vermutet\n  - im Workspace liegen 7 wt/-Worktrees unter _WORK_/worktrees/xserver/

- 2026-10-01T11:39:58Z Laforge: progress 10% (Starting documentation task: adding branch namespace conventions and tmp-staging branch documentation to doc/USER.md and doc/github.md)

- 2026-10-01T11:45:16Z Laforge: progress 100% (Documentation added to doc/USER.md (section 4.11 Branch Namespaces) and doc/github.md (xx-make-pr section):
- Branch Namespaces table: wt/, pr/, tmp-pr/, rfc/, wip/, fix/, submit/
- tmp-pr/ staging branch: created as tmp-<branchName>, renamed to pr/... before push, never pushed, left behind on error intentionally
- Git D/F conflict warning with reproduction steps
- No-cleanup-on-error documented as intentional (for manual recovery)
)
