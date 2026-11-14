Title: "Comms routing: case-insensitive ship lookup + collision detection"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-14T15:13:10Z"
Doc-Ref: "—"

Fix case-sensitive ship/user-part resolution in Comms address-to-local-ship resolution. Add deterministic case-insensitive lookup with ambiguity detection: exact-case match, case-insensitive match, no-match error, two-colliding-entries error. Preserve original display spelling; do not rename spool dirs. Local forms: bare recipient and @local. Remote domains (pegasus) still route through transport. Tests: exact match, case-insensitive match, no match, collision, local routing.

- 2026-11-14T15:13:29Z Voyager: began work

- 2026-11-14T15:29:12Z Voyager: completed

- 2026-11-14T15:45:06Z Voyager: progress 75% (Adding focused tests: BeTa@LOCAL mixed-case local lookup, remote-domain bob@peer.example with colliding local bob mailbox (must reach transport, no local write), unknown/unavailable remote domain remains error)

- 2026-11-14T15:52:15Z Voyager: completed

- 2026-11-14T16:04:05Z Voyager: progress 100% (Task complete; starting Wormhole-reply chat surfacing. HEAD 7ece6206e34f91febb335477760c5f89e2ab2e7f (work/wormhole-manager-w0-017, pushed, deployed), existing Voyager session ses_ebabda49affeLotdkpUHrOc86H PID 11800.)
