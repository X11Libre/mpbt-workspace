Title: "Audit complete - temp directory/permission policy"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-16T13:25:49Z"
Doc-Ref: "—"

READ-ONLY audit of Starfleetctl temp directory and permission policy completed. Root cause: console ships (launchType=terminal) get external_directory '**' = 'ask' which prompts on any /tmp access. Environment inherits TMPDIR/TMP/TEMP with no redirection to per-ship scratch. Three policy options analyzed: (1) Hard-deny global /tmp + per-ship TMPDIR redirect (RECOMMENDED), (2) Hard-allow /tmp globally (high risk), (3) Isolated per-ship mount namespace (overkill). Files: launch.go childEnv + generateOpencodeConfig external_directory rules.

- 2026-11-16T13:26:13Z Voyager: progress 100% (Audit completed and documented - root cause identified, three policy options compared with risks, Option 1 recommended)
