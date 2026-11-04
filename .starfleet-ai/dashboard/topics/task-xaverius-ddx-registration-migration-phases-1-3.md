Title: "Xaverius: DDX Registration & Migration Phases 1-3"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-11-04T19:46:55Z"
Assigned-To: "Defiant"
Doc-Ref: "—"
Slug: task-xaverius-ddx-registration-migration-phases-1-3

Migration Plan Phases 1-3: (1) DDX-wide discovery vs Screen setup trennen; Screen-Callbacks entfernen, DDX Registration Entry Point. (2) Snapshot vs Binding trennen: ProviderCapabilities -> Snapshot-only, ProviderCallbacks löschen, 4 Operation Tables definieren, Binding mit native handle/context/ops/binding_generation/ModuleRole. (3) Atomic per-device Registration Transaction: Identity Evidence + native handle + context + ops + ModuleRole generation, duplicate-safe, identity evidence hierarchy. Repository: X11Libre/xserver:wip/xaverius
