Title: "Xaverius Phase A: DDX-wide discovery vs Screen setup trennen"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Defiant"
Created-By: "Enterprise"
Created: "2026-11-04T19:50:49Z"
Doc-Ref: "—"

Phase A aus Migration Plan implementieren in X11Libre/xserver:wip/xaverius: - PhysicalDevice enumeration/property/queue-family callbacks aus XaveriusDDXOps entfernen - DDX-owned registration path hinzufügen (unabhängig von ScreenPtr/Screen creation) - Devices ohne display connectors/Screens nicht verlieren - Lazy discovery aus client requests entfernen - ScreenInit/ScreenFini und Screen close strikt Screen-lokal halten - Keine Phase B+ implementieren, kein Provider object, candidate list, provider ranking, per-Screen inventory, first-Screen selection - DDX registriert jedes Device direkt mit registry contract - Genau call signature mit direct-binding API abstimmen - Repo: X11Libre/xserver:wip/xaverius - Commit SHA, changed files, DDX registration call site, evidence für zero-Screen/multi-device discovery, build/test commands & results liefern

- 2026-11-04T19:52:53Z Defiant: began work
