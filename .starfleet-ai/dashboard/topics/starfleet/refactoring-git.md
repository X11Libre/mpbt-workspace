Title: "starfleet: internes refactoring: git utilty class"
Category: active
Status: "in-progress"
Assigned-To: "Aeon"
Created-By: ""
Created: ""
Doc-Ref: ""

Internes refactoring: git-operationen in separate utility class / module auslagern.
evtl. alle utils unter `./util` legen.

Analog dazu mit github api access.

- 2026-09-07T09:31:27Z Aeon: began work

- 2026-09-07T10:09:12Z Aeon: Analyse: git-Operationen in starfleetctl verstreut (exec.Command in ghpr, session, timer, web, worktree, modelproxy, ocsessions). Kein zentrales git-util. Ziel: ./internal/util/git.go mit Git-Operationen (clone, fetch, rev-parse, status, diff, commit, push, branch, remote). Auch GitHub API (gh) in ./internal/util/gh.go auslagern (analog xxmakepr.go).
