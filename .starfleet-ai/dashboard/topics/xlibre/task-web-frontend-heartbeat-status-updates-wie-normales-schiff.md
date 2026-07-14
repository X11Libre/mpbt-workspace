---
title: "Web-Frontend Heartbeat: Status-Updates wie normales Schiff"
category: active
kind: "task"
status: "done"
assigned-to: "Phoenix"
created-by: "Phoenix"
created: "2026-07-30T08:36:12Z"
doc_ref: "—"
---

Das starfleet Web-Frontend (internal/web/web.go) soll sich per Heartbeat auf dem Fleet-Board registrieren, genau wie CLI/opencode ships. Änderungen in starfleet-repo: initialen DoStatus() beim Start, periodischen DoTouch() via Goroutine, und DoClear() beim Shutdown.
