Subject: "starfleet: timer log im falschen directory"
Category: starfleet
Kind: "task"
Status: "done"
From: "McKinley"
Date: "2026-09-11T15:05:25Z"
Doc-Ref: "—"

sollte mit zu den anderen logs unter .starfleet-ai/var/logs

- 2026-09-17T17:10:00Z Scotty: **ERLEDIGT** — Timer-Worker Log von `.starfleet-ai/var/comms/logs/` nach `.starfleet-ai/var/logs/` verschoben (konsistent mit anderen Logs). Symlink für Rückwärtskompatibilität erstellt. `internal/timer/worker.go`: `openLogFile` nutzt nun `config.WorkDir(root)` + "logs" (also `.starfleet-ai/var/logs/`). Build grün.
