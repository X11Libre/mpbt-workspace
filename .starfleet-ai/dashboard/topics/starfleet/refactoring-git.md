Title: "starfleet: internes refactoring: git utilty class"
Category: active
Status: "open"
Assigned-To: "Aeon"
Created-By: ""
Created: ""
Doc-Ref: ""

Internes refactoring: git-operationen in separate utility class / module auslagern.
evtl. alle utils unter `./util` legen.

Analog dazu mit github api access.

- 2026-09-07T09:31:27Z Aeon: began work

- 2026-09-07T10:09:12Z Aeon: Analyse: git-Operationen in starfleetctl verstreut (exec.Command in ghpr, session, timer, web, worktree, modelproxy, ocsessions). Kein zentrales git-util. Ziel: ./internal/util/git.go mit Git-Operationen (clone, fetch, rev-parse, status, diff, commit, push, branch, remote). Auch GitHub API (gh) in ./internal/util/gh.go auslagern (analog xxmakepr.go).

- 2026-09-07T10:54:04Z Aeon: Rate-Limit-Sturm (429 NIM API) blockiert weitere Arbeit. Plugin reagiert korrekt: transient errors erkannt → session cleared → synthetic restart. Keine Mails an Flagschiff (error-handling-1 compliant). Warte auf Rate-Limit-Recovery.
