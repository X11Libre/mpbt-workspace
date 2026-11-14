Title: "Comms routing: case-insensitive ship lookup + collision detection"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-11-14T15:13:10Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-comms-routing-case-insensitive-ship-lookup-collision-detection

Fix case-sensitive ship/user-part resolution in Comms address-to-local-ship resolution. Add deterministic case-insensitive lookup with ambiguity detection: exact-case match, case-insensitive match, no-match error, two-colliding-entries error. Preserve original display spelling; do not rename spool dirs. Local forms: bare recipient and @local. Remote domains (pegasus) still route through transport. Tests: exact match, case-insensitive match, no match, collision, local routing.
