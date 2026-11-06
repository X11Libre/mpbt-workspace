Title: "Xaverius: Hotplug/Unload/Shutdown & Request Snapshot Semantics (Phases 5&7)"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Enterprise"
Created: "2026-11-04T19:48:31Z"
Doc-Ref: "—"

Migration Phases 5&7: (5) Request Snapshot Semantics: Enumerate alle retained (AVAILABLE/UNAVAILABLE/REMOVED), Property/QueueFamily via immutable snapshot, AVAILABLE != identity existence, property-specific status mapping, keine fabricated defaults. (7) Hotplug/Unload/Shutdown: Registry shutdown in server shutdown path, DDX unload (admission close, Screen detach, binding withdraw, drain, quiesce, lease release), binding removal affects one device, ModuleRole drains all bindings. Async callbacks: server token ID + binding/module-role generations. Quarantine bei ungewisser quiescence. Repository: X11Libre/xserver:wip/xaverius
