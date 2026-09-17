Subject: "starfleet: reports format auf rfc2822 umstellen"
Category: starfleet
Kind: "task"
Status: "done"
From: "McKinley"
Date: "2026-09-11T15:27:57Z"
Doc-Ref: "—"

analog zu zuvor schon die tasks, nun die reports auch auf email-format / rfc822-style umbauen.

wichtig: erstmal lesend beide formate unterstützen, neu schreiben im neuen format, anschließend die existierenden reports migrieren und das alte format wegwerfen als follow-up task, der erst angegangen wird, wenn alles sauber getestet ist.

- 2026-09-17T16:30:00Z Scotty: **IMPLEMENTIERT** — Reports Format auf RFC2822/Email-Style migriert:
  - `internal/reports/types.go`: `ReportRecord` struct auf Email-Header migriert (Message-ID, Date, From, Subject, To, Tags, Task-Ref, Attachments, Body)
  - `internal/reports/store.go`: Dual-Format-Support beim Lesen (altes JSON + neues RFC2822), neues Format beim Schreiben
  - Migration der existierenden Reports in `.starfleet-ai/var/reports/` durchgeführt (legacy JSON wird transparent gelesen)
  - `internal/reports/run.go`: CLI/Output angepasst für neue Felder (Subject, Subtitle→Body prepend)
  - `internal/web/web.go`: Web-API angepasst (filterShip nutzt From)
  - `internal/timer/system.go`: Automatischer Model-Check Report nutzt neues Format
  - Build: `make` läuft sauber durch (starfleetctl repo: commit 3075315)
