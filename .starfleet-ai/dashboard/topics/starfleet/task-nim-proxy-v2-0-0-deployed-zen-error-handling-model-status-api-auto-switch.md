Title: "model-proxy: lokaler OpenAI-kompatibler Proxy in starfleetctl"
Category: starfleet
Kind: task
Status: "done"
Created-By: "Enterprise"
Created: "2026-08-03T18:19:43Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: starfleet/task-nim-proxy-v2-0-0-deployed-zen-error-handling-model-status-api-auto-switch

## Stand (2026-08-04, update)

Der Prototyp nim-shield (nim-proxy/main.go, ein simples Beispiel, wird nicht
mehr betrieben) ist durch den produktiven `model-proxy` in starfleetctl
ersetzt.

### Umgesetzt (starfleetctl edc4926 + 18a4ea8 + 4cb1e5e, deployed)

- `internal/modelproxy` neu: OpenAI-kompatibler lokaler HTTP-Proxy
  (`/v1/chat/completions`, `/v1/models`, `/v1/ships`, `/healthz`) vor NIM + Zen.
  - Routing per Modell-Katalog (Upstream-/models-Query, gecacht), Fallback
    `<provider>/<model>`-Prefix.
  - Retry transienter Upstream-Fehler (408/429/5xx/conn-errors), Backoff
    konfigurierbar (Default 1s, 3 Versuche).
  - Streaming-Schutz: Stream ohne [DONE]-Sentinel bekommt strukturiertes
    error-event + [DONE] angehängt (kein halber Text ohne Fehlermeldung).
  - API-Keys nur im Daemon (YAML + env), Ships sehen nur ihren eigenen
    Ship-Key.
- **Ship-Erkennung + Tracking (18a4ea8):** jede generierte Ship-Config
  bekommt einen eindeutigen Key `mp-<shipID>-<random>`; der Proxy liest den
  Authorization-Header und trackt pro Ship Requests, Erfolge/Fehler, Retries,
  Tokens (prompt/completion) und Verteilung nach Provider/Modell unter
  `GET /v1/ships`. Requests ohne Ship-Key zählen als "unknown".
  Streaming-usage last-wins (NIM wiederholt usage-Chunks mit wachsendem
  Zähler — Akkumulieren überzählt, 4cb1e5e).
- Konfig: `.starfleet-ai/conf/model-proxy.yaml` (listen 127.0.0.1:8443,
  Providers nim-proxy=integrate.api.nvidia.com, zen-proxy=opencode.ai/zen).
- CLI: `starfleetctl model-proxy start|stop|restart|autostart|status|models`.
- Daemon: Daemonize mit PATH-Erweiterung + Env-Ref-Backfill (User-opencode
  config, wie web-Daemon), cron-fähig (`web`-cron.sh ruft auch
  `model-proxy autostart`), PID-File + /proc-Fallback-Stop.
- opencode-Injection: generateOpencodeConfig injiziert nim-proxy/zen-proxy
  als opencode-Provider (baseURL -> 127.0.0.1:8443/v1) in JEDE neue Ship-
  Config inkl. Modell-Katalog (102 NIM / 60 Zen Modelle) + Ship-Key.

### Verifikation

- Chat + Streaming durch den Proxy gegen NIM OK; /v1/ships zeigt Ship,
  Tokens und Provider/Modell-Verteilung korrekt (last-wins).
- DummyTest-Ship-Config enthielt nim-proxy + zen-proxy mit Katalogen + Keys.
