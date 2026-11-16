Title: "Audit Starfleetctl temp directory/permission policy"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-16T13:08:17Z"
Doc-Ref: "—"

READ-ONLY audit of temp directory and permission policy, especially why console ships hit permission-ask on /tmp access. Inspect runtime permission/sandbox config, console vs background launch paths, env propagation, SOP/prompt sources, tool/build subprocess behavior. Compare policy options and recommend narrowest safe policy.

- 2026-11-16T13:08:43Z Voyager: progress 5% (Closing out outbox audit report, starting temp directory policy investigation)

- 2026-11-16T13:23:57Z Voyager: progress 70% (Completed temp directory/permission policy audit - found root cause of console ship permission prompts on /tmp access)

- 2026-11-16T13:24:51Z Voyager: progress 100% (Audit complete - root cause identified, three policy options compared, Option 1 recommended)
