Title: "Xaverius: Implementation Guidance Follow-up (6 Fragen vom Design-Agent)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-11-04T19:49:28Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: task-xaverius-implementation-guidance-follow-up-6-fragen-vom-design-agent

Design-Agent fordert konkrete Evidenz (keine Absichtserklärungen): 1) Xlibre Object/API für server-owned loader pin (dlclose proof). 2) udev/hotplug hook names + event sequencing. 3) Authoritative per-bus identity mapping (primary/render DRM). 4) DDX backend split: multiple PhysicalDevices per context, multiple contexts per module, independent DDX sources same PhysicalDevice. 5) Module-global workers/callbacks inventory + lifetime pinning. 6) Integration order/tests: hotplug-during-scan, two Screens/one GPU, one Screen/multiple GPUs, delayed callbacks after Screen close, unload after final Screen removal. Evidenz: Repository, Branch, Commit SHA, Source Paths, Tests. Report in IMPLEMENTATION_COORDINATION.md.
