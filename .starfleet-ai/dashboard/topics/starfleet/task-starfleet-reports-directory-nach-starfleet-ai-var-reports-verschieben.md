Subject: "starfleet: reports directory nach .starfleet-ai/var/reports verschieben"
Category: starfleet
Kind: "task"
Status: "done"
From: "McKinley"
Date: "2026-09-11T15:37:42Z"
Doc-Ref: "—"

- 2026-09-17T13:06:05Z Scotty: completed (unassigned, dann neu zugewiesen)
- 2026-09-17T16:20:00Z Scotty: **ERLEDIGT** — Reports directory von `.starfleet-ai/reports/` nach `.starfleet-ai/var/reports/` verschoben (unter var/ für Runtime-State-Konsistenz). Symlink `.starfleet-ai/reports` → `var/reports` für Kompatibilität erstellt. `internal/reports/store.go` angepasst (`NewStore` nutzt nun `var/reports/`). Build grün.
