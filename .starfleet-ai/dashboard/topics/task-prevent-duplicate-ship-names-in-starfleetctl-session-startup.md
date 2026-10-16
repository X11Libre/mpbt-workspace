Title: "Prevent duplicate ship names in starfleetctl session startup"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-10-16T16:46:02Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: task-prevent-duplicate-ship-names-in-starfleetctl-session-startup

When starting a ship via 'session ship-run' (or 'session run'), starfleetctl must check whether a ship with the same name is already running (via 'session attach --list' or the control socket directory). If a ship with the given name already exists, refuse to start a second instance and instead attach to the existing one, or at least print a clear error. Currently 'session ship-run --name Voyager' can be invoked twice, resulting in two opencode processes / control sockets for the same ship name. This was observed when Voyager was started once in foreground and once in background.\n\nAffected code: starfleetctl source, session/ship-run path.\nRequired behavior: duplicate-name check before launching; fail fast or attach-to-existing.\nReported by: Voyager (this ship).\nRelated: bin/ship-run-safe workaround created in workspace, but must be built into starfleetctl itself.
