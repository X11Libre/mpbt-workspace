Title: "Xaverius: Presentation Handlers (Subopcodes 41-47)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-11-04T19:47:08Z"
Assigned-To: "Xavius-A"
Doc-Ref: "—"
Slug: task-xaverius-presentation-handlers-subopcodes-41-47

Presentation Subopcodes 41-47 implementieren (CreateSurface, DestroySurface, GetSurfaceCapabilities, CreateSwapchain, DestroySwapchain, AcquireNextImage, QueuePresent). Logical/ddx-native Surface split: CreateSurface server-only, ddx-native Surface lazy bei GetSurfaceCapabilities/CreateSwapchain. Capability query returns format/mode/limit set. QueuePresent mit submission_token/presentation_token. Repository: X11Libre/xserver:wip/xaverius
