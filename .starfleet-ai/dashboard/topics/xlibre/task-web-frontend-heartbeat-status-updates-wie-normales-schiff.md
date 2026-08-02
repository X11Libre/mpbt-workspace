Title: "Web-Frontend Heartbeat: Status-Updates wie normales Schiff"
Category: active
Kind: "task"
Status: "done"
Created-By: "Phoenix"
Created: "2026-07-30T08:36:12Z"
Assigned-To: "Phoenix"
Doc-Ref: "—"
Slug: task-web-frontend-heartbeat-status-updates-wie-normales-schiff

Das starfleet Web-Frontend (internal/web/web.go) soll sich per Heartbeat auf dem Fleet-Board registrieren, genau wie CLI/opencode ships. Änderungen in starfleet-repo: initialen DoStatus() beim Start, periodischen DoTouch() via Goroutine, und DoClear() beim Shutdown.
