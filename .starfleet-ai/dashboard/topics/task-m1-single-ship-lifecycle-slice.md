Title: "M1 single-ship lifecycle slice"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-11-14T12:21:18Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-m1-single-ship-lifecycle-slice

Bounded M1 package: ship receives a task (capture), works it (in-progress), ends with explicit terminal outcome (completed/blocked/yielded), durable progress+final report, and failed-handoff retry targeting the same session (no duplicate session). Acceptance: task lifecycle exercises capture→begin→progress→done; plugin exposes blocked/yielded outcomes; focused Go+TS tests pass; committed and pushed.
