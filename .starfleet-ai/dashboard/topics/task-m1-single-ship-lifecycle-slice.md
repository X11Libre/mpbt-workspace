Title: "M1 single-ship lifecycle slice"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-14T12:21:18Z"
Doc-Ref: "—"

Bounded M1 package: ship receives a task (capture), works it (in-progress), ends with explicit terminal outcome (completed/blocked/yielded), durable progress+final report, and failed-handoff retry targeting the same session (no duplicate session). Acceptance: task lifecycle exercises capture→begin→progress→done; plugin exposes blocked/yielded outcomes; focused Go+TS tests pass; committed and pushed.

- 2026-11-14T12:21:33Z Voyager: began work
