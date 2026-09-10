Title: "Model-Proxy: Retry-Verbesserungen gegen anhaltende 429-Rate-Limits"
Category: active
Kind: task
Status: "assigned"
Created-By: "Defiant"
Created: "2026-09-10T09:10:08Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: task-model-proxy-retry-verbesserungen-gegen-anhaltende-429-rate-limits

Der aktuelle Proxy-Retry-Mechanismus (MaxRetries=3, RetryDelayMS=1000, fixes Backoff) reicht bei anhaltendem Rate-Limit nicht aus. Die Folge: opencode erschöpft seine eigenen Retries und generiert synthetische Restarts (neuer Turn, neuer Context). Verbesserungen:
1. Exponentielles Backoff NUR bei anhaltender Störung (nicht sofort) — z.B. erst ab 3. aufeinanderfolgendem 429
2. Retry-After Header des Upstreams respektieren (wenn vorhanden)
3. Prüfen ob opencode eigene Retry-Limits hat und ob diese erhöht werden können/should
4. Ggf. longer-term Backoff (Sättigung erkannt → länger warten)

Scotty arbeitet aktuell am starfleetctl-Source — Änderungen am Proxy erst nach Freigabe.
