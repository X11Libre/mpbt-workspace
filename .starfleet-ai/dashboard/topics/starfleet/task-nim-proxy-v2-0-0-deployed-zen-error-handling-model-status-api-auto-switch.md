Title: "model-proxy: lokaler OpenAI-kompatibler Proxy in starfleetctl"
Category: starfleet
Kind: task
Status: "done"
Created-By: "Enterprise"
Created: "2026-08-03T18:19:43Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: starfleet/task-nim-proxy-v2-0-0-deployed-zen-error-handling-model-status-api-auto-switch

## Stand (2026-08-04, update 3)

### Modell-Metadaten in Ship-Configs (6eaccd6)

Frage "kann der Proxy die Metadaten so servieren, dass opencode sie hat wie
bei echten Servern?" → Ja, aber nicht über /v1/models: der openai-kompatible
Provider in opencode liest die Metadaten (label/context/caps) aus der
Provider-"models"-Map der opencode.json, nicht aus der /v1/models-Antwort
(dort nur IDs). Daher:

- `modelEntryFor()` mappt die Proxy-ModelInfo (label, context, caps) auf das
  opencode-Schema: name, limit.context, reasoning/attachment/tool_call,
  modalities input/output.
- `ProviderConfigs` (generateOpencodeConfig) schreibt diese Metadaten jetzt
  in jede generierte Ship-Config (verifiziert mit DummyMeta-Ship: 102
  nim-proxy + 60 zen-proxy Modelle, DeepSeek V4 Flash mit context 1048576 +
  reasoning, Big Pickle mit context 200000).
- Damit haben Ships dieselbe Oberfläche wie bei direkten Providern (models.dev).

### Vorherige Updates

- /v1/models reicht id/created/owned_by (Upstream) + label/context/caps
  (opencode-Katalog) durch; model-query direkt gegen Upstream, nie models.yaml.
- models sync nimmt Proxy-Backends in models.yaml auf → Web-Auswahl (242).
- Ship-Tracking via mp-<shipID>-Key + GET /v1/ships; NIM-Usage last-wins.
