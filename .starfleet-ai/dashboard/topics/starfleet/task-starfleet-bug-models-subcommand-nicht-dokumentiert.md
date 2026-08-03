Title: "starfleet: bug: models subcommand nicht dokumentiert"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Stargazer"
Created-By: "Discovery"
Created: "2026-07-31T14:27:19Z"
Doc-Ref: "—"

auf der main-helppage von starfleetctl muß das models subcommand dokumentiert sein. ebenso in der user-doku.
Already implemented: commit 4e3c8d9 (2026-08-02) added "models" to the main
help page (cmd/starfleetctl/main.go) and to doc/USER.md (reference table +
models.yaml tree entry). Verified 2026-08-03 on the deployed binary:
`starfleetctl --help` lists models; `starfleetctl models --help` shows full
usage. Closing.
