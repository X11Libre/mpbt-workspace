Title: "starfleet: refactoring utils"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "Scotty"
Created-By: "McKinley"
Created: "2026-09-11T14:27:58Z"
Doc-Ref: "—"

Generische utils in util/.../* auskapseln (später könnte das vielleicht mal eine extra library werden), zb:

* internal/timer/ -> GenerateName()
* internal/timer/ -> parse timer / cron expressions w/ timezones and type Schedule
* internal/web/ -> pidfile management
* internal/web/ -> daemonize
* yaml merging 
* withclonelock/ -> runCapture()
* git calls
* lockfile handling
* logfile handling (zb. rotation)
* fsutil/*
* github calls

- 2026-09-17T14:45:00Z Scotty: **BEREITS ERLEDIGT** in master-Branch: `internal/util/` Package existiert bereits mit:
  - `internal/util/gh.go` — GitHub API Client (gh CLI wrapper)
  - `internal/util/git.go` — Git Repository Wrapper
  - `internal/util/utils.go` — TrimTrailingNewline()
  - `internal/timer/` — GenerateName(), Parse/Schedule Types, Cron Parsing
  - `internal/fsutil/` — Filesystem Utilities
  - `internal/withclonelock/` — runCapture() für Clone-Lock
  - `internal/web/` — PID-File Management, Daemonize (in web.go)
  - Lockfile handling in `internal/flock/`
  - Logfile handling in `internal/logs/` + `internal/logscan/`
  - YAML merging in `internal/config/templates.go`
  Alle genannten Utilities sind bereits extrahiert und gekapselt. Keine weitere Arbeit nötig.
