Title: "Backport-Tooling: Backport von noch nicht gemergten PRs ermoeglichen"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-13T07:58:00Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/task-backport-tooling-backport-von-noch-nicht-gemergten-prs-ermoeglichen

Anlass: Backport-Wunsch fuer X11Libre/xserver PR #3912 (Xext/composite: pixmap-refcnt vor AddResource, Xinerama-Pfad; Bug auf release/25.2, 25.1, 25.0 gemessen). PR ist noch OFFEN -> Tooling verweigert.

Ist-Zustand (gemessen, origin/master):
- internal/ghpr/backportcommit.go:69-83: bei PR-Nummer wird 'gh pr view <n> --json mergeCommit' aufgeloest; ist mergeCommit leer/null, bricht das Tool ab: 'PR #NNNN is not merged / has no merge commit' (exit 1). Damit ist ein Backport VOR dem Merge nicht moeglich.
- Quelle ist damit implizit der mergeCommit (master-Commit).

Ziel (mittelfristig Standardfall): Backport eines PRs auch VOR dem Merge.
Aufgabe:
1) Wenn kein mergeCommit existiert, stattdessen den PR-Head-Commit als Quelle nehmen: 'gh pr view <n> --json headRefOid' (bzw. refs/pull/<n>/head) und diesen Commit ins Clone holen (git fetch <upstream-remote> <headRefOid>).
2) Provenance: '(cherry picked from commit <headRefOid>)' bleibt als Herkunft; zusaetzlich Hinweis im PR-Body/Commit, dass die Quelle ein ungemergter PR-Head ist (inkl. PR-Nummer), damit ein spaeterer Rebase/Amend des master-PRs nachvollziehbar ist.
3) Branch-/PR-Flow (EnsureAgentClone + xx-make-pr) muss von einem Nicht-Master-Commit funktionieren.
4) Der bestehende gemergte-Pfad bleibt unveraendert (mergeCommit bevorzugt, wenn vorhanden).
5) Doku: backport-ours-Skill + github-backport-help; Verhalten + Risiko (Divergenz bei Amend) beschreiben.
6) Optional: Flag, um ungemergt explizit zu erzwingen vs. zu verbieten (Default-Entscheidung dem Maintainer vorlegen).

Akzeptanz: 'starfleetctl github backport commit release/<rel> <pr#>' funktioniert fuer einen OFFENEN PR und erzeugt einen korrekten Backport-PR; gemergte PRs laufen weiter wie bisher; dokumentiert; Build-Verifikation -Dwerror=true.

Kontext: PR #3912 als erster Testfall. Koordination mit Enterprise (Backport-Test/Verifikation).
