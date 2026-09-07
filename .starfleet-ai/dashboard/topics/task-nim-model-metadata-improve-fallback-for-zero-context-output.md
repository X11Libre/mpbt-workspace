Title: "NIM model metadata: improve fallback for zero context/output"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-09-07T17:34:05Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: task-nim-model-metadata-improve-fallback-for-zero-context-output

Modify modelEntryFor in modelproxy/occonfig.go to set limit.context/limit.output individually when >0, rather than requiring both >0
