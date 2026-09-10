Title: "NIM model metadata: improve fallback for zero context/output"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "Enterprise"
Created-By: "Voyager"
Created: "2026-09-07T17:34:05Z"
Doc-Ref: "—"

Modify modelEntryFor in modelproxy/occonfig.go to set limit.context/limit.output individually when >0, rather than requiring both >0
