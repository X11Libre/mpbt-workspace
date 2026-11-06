Title: "Xaverius: Presentation Handlers (Subopcodes 41-47)"
Category: active
Kind: "task"
Status: "superseded"
Assigned-To: "Xavius-A"
Created-By: "Enterprise"
Created: "2026-11-04T19:47:08Z"
Doc-Ref: "—"

Presentation Subopcodes 41-47 implementieren (CreateSurface, DestroySurface, GetSurfaceCapabilities, CreateSwapchain, DestroySwapchain, AcquireNextImage, QueuePresent). Logical/ddx-native Surface split: CreateSurface server-only, ddx-native Surface lazy bei GetSurfaceCapabilities/CreateSwapchain. Capability query returns format/mode/limit set. QueuePresent mit submission_token/presentation_token. Repository: X11Libre/xserver:wip/xaverius

- 2026-11-04T19:54:56Z Xavius-A: progress 100% (All 7 presentation subopcodes (41-47: CreateSurface, DestroySurface, GetSurfaceCapabilities, CreateSwapchain, DestroySwapchain, AcquireNextImage, QueuePresent) implemented on branch rfc/xaverius-presentation (commit 47e46a92bf). Compile-checked clean -Wall -Werror -Wextra against real xserver includes.)

- 2026-11-04T19:55:15Z Xavius-A: completed

- 2026-11-04T20:08:02Z Enterprise: completed
