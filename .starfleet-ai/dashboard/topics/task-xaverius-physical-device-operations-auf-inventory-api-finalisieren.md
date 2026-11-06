Title: "Xaverius: Physical Device Operations auf Inventory API finalisieren"
Category: active
Kind: "task"
Status: "superseded"
Assigned-To: "Defiant"
Created-By: "Enterprise"
Created: "2026-11-04T19:46:19Z"
Doc-Ref: "—"

3 Handler (EnumeratePhysicalDevices, GetPhysicalDeviceProperty, GetPhysicalDeviceQueueFamilyProperties) vollständig auf xaverius_inventory API umstellen: XID-Lookup via Inventory, caps aus Inventory, keine Screen-Iteration mehr. Atom-Vergleich via MakeAtom, Property-Typen korrigiert (XAV_PROPERTY_BYTE_ARRAY etc.). Build sauber. Commit b55b3fe8f0 als Basis.
