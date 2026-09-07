Title: "Web ship spawn model selection broken"
Category: starfleet
Kind: "task"
Status: "in-progress"
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: "2026-09-07T18:10:21Z"
Doc-Ref: "—"

When spawning a ship via web console, the model selected in the form is not being used. Ships start with the last model used in opencode instead of the selected model.

- 2026-09-07T18:37:07Z Enterprise: began work

- 2026-09-07T18:43:39Z Enterprise: progress 10% (Investigating: web form model selection not passed to LaunchShip. Checking apiShipLaunch and generateOpencodeConfig.)

- 2026-09-07T18:50:05Z Enterprise: progress 30% (Found root cause: web UI sends model ID with provider prefix (e.g. 'nim-proxy/nvidia/nemotron-3-ultra-550b-a55b') but proxy's /v1/models returns IDs without prefix (e.g. 'nvidia/nemotron-3-ultra-550b-a55b'). Opencode can't find model in provider's catalog, falls back to last used model. Fix: strip provider prefix before passing to opencode config and --model flag.)
