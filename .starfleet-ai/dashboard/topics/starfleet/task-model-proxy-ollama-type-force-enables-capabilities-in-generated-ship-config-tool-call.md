Title: "model-proxy: ollama type force-enables capabilities in generated ship config (tool_call)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-09T09:13:30Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-model-proxy-ollama-type-force-enables-capabilities-in-generated-ship-config-tool-call

Ollama /v1/models liefert keine Capability-Metadaten, dadurch wurden Ollama-Modelle in der generierten opencode.json ohne tool_call behandelt. Fix: provider type "ollama" + Provider.forcedModelCaps() (Default toolcall+temperature, überschreibbar via capabilities: Liste) + modelEntryFor(inf, forcedCaps). Deployed: starfleetctl 3fa6df0 (origin/master), model-proxy pid 11347. Verifiziert via run --name DummyOlla: alle 5 Ollama-Modelle haben tool_call+temperature.
