Title: "Implement starfleetctl session transcript command"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: ""
Created-By: ""
Created: "2026-09-10T08:13:21Z"
Doc-Ref: "—"

Add a subcommand to extract Opencode session transcript from SQLite DB and output to file or stdout, similar to web frontend's ocsessions.SessionTranscript

- 2026-09-10T08:19:35Z Enterprise: Implemented 'session transcript <id> [--limit/--offset/--output/--json|--text]' in internal/session/transcript.go, wired into run.go, exported ocsessions.MaxListLimit(). Tests green in clean worktree at HEAD. Committed cf7afb3 + pushed to master.
