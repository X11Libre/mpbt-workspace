Title: "merge go-x11proto wip/termctl-scrollback-dimensions into master"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Enterprise"
Created: "2026-08-07T08:28:47Z"
Doc-Ref: "—"

Prüfe ob dieser Task überhaupt noch aktuell ist - möglicherweise schon längst erledigt.
Fall schon erledigt, dann aufräumen (task, worktrees, branches etc). Aber nichts löschen das nicht verifiziert obsolet ist.

---

starfleetctl's internal/session/launch.go uses termctl.WithRows/WithCols/WithScrollbackCap, which only exist on go-x11proto branch wip/termctl-scrollback-dimensions (commits e1ae22b, 6c6be75 — 2 ahead of master). The starfleetctl go.mod temporarily points at the local worktree holding that branch (commit ead0c16). Once the branch lands on go-x11proto master, revert that go.mod redirect. Coordinate with Stargazer (worktree owner).
