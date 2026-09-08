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

- 2026-09-08T08:28:30Z Enterprise: CORRECTED root cause (earlier note is WRONG — do not strip provider prefix, that breaks resolution): opencode resolves prefixed 'nim-proxy/<model>' ids correctly and working ships use them. The observed fallback-to-last-model happens ONLY when the selected model isn't actually served by the provider (nim-proxy is free-only, exposes only nemotron; DeepSpace1/2 requested deepseek -> filtered out -> opencode falls back). So the model IS passed/used when available. Real gap: no clear warning when a selected model is unavailable -> silent fallback. validateModelAvailable() (new, uncommitted in launch.go) aims to detect this but currently compares prefixed id against bare list so it never matches. NOTE: shared SRC tree is dirty (Defiant's model-proxy-model-config WIP) and did NOT build (modelListFor->ModelListFor rename left 2 stale call sites); I fixed the 2 call sites to restore the build. Coordination with Defiant needed.

- 2026-09-08T11:08:19Z Enterprise: progress 80% (Web-Dropdown-Filter fertig: branch starfleet-web-model-filter @90cb4c8 (gepusht). filterAvailableModels() filtert proxied Provider auf tatsaechlich served Modelle (free-only-aware), Nicht-Proxied bleiben, Fallback: bei Query-Fehler Modelle behalten. Unit-Tests (bareModelID, modelSet, filterAvailableModels inkl. Stub-/v1/models) gruen; make all gruen. Integration auf master: Koordination mit Defiant/Praetor ausstehend.)
