Title: "Xaverius: Physical Device Operations auf Inventory API finalisieren"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-11-04T19:46:19Z"
Assigned-To: "Defiant"
Doc-Ref: "—"
Slug: task-xaverius-physical-device-operations-auf-inventory-api-finalisieren

3 Handler (EnumeratePhysicalDevices, GetPhysicalDeviceProperty, GetPhysicalDeviceQueueFamilyProperties) vollständig auf xaverius_inventory API umstellen: XID-Lookup via Inventory, caps aus Inventory, keine Screen-Iteration mehr. Atom-Vergleich via MakeAtom, Property-Typen korrigiert (XAV_PROPERTY_BYTE_ARRAY etc.). Build sauber. Commit b55b3fe8f0 als Basis.
