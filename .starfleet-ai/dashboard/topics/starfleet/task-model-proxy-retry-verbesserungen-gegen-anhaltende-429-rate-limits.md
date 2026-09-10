Title: "Model-Proxy: Retry-Verbesserungen gegen anhaltende 429-Rate-Limits"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "Scotty"
Created-By: "Defiant"
Created: "2026-09-10T09:10:08Z"
Doc-Ref: "—"

## Problem

Der aktuelle Proxy-Retry-Mechanismus (MaxRetries=3, RetryDelayMS=1000, fixes Backoff) reicht bei anhaltendem Rate-Limit nicht aus. Die Folge: opencode erschöpft seine eigenen Retries (maxRetries=8, exp. Backoff 2s-307s) und generiert synthetische Restarts (session.clear + promptAsync).

## Praetor-Entscheidung (2026-09-10)

- **Keepalive-Hold:** hold_timeout_ms=15000 als Default UND Maximum. Nur fuer stream:true (SSE). NIM als erste Instanz, Zen default aus.
- **Global Saturation Gate:** Fuer ALLE Pfade (normaler Retry UND Hold). Ein einzelner Retry-After-respektierender Timer pro Provider, kein individuelles Hold pro Request.
- **Model-Switch during Hold:** Default AUS. Opt-in bei persistenter Sättigung.

## Spezifikation

### 1. SSE Keepalive-Buffer (stream:true only)

Wenn upstream 429 liefert (nach Erschoepfung von max_retries):
- Proxy haelt die Verbindung offen
- Sendet SSE-Kommentare ': keepalive\n\n' alle 3s
- opencode-Parser ignoriert Kommentare → Verbindung bleibt lebendig
- Nach hold_timeout_ms (15s) → finaler 429 an opencode

### 2. Global Saturation Gate

- Erkennung: transientStatus(429) oder retryableErrorText('ResourceExhausted')
- Provider-Flag saturated=true + Retry-After-respektierender Cooldown-Timer
- ALLE neuen Requests zu dem Provider → warten hinter dem Timer
- Reset: nach Erfolg oder Expiry

### 3. Transition-Logik

proxy-max_retries (3) → Keepalive-Hold bis hold_timeout (15s) → finaler 429 → opencode-8-Retry-Fallback erhalten bleibt.

## Code-Referenzen

- opencode-core: internal/llm/provider/provider.go (maxRetries=8)
- opencode-core: internal/llm/provider/openai.go (shouldRetry: 429/500, exp. Backoff)
- Proxy: internal/modelproxy/proxy.go (forwardChat, transientStatus, pipeSSE)
- Proxy: internal/modelproxy/config.go (MaxRetries=3, RetryDelayMS=1000 defaults)
- Plugin: fragments/opencode-plugins/starfleet-dispatch.ts (pollRetryStatus, executeAction)
- Error-Klassifizierung: internal/comms/error.go (ClassifyModelError, decideAction)

## Offene Punkte

- [ ] Warte auf Scotty Tree-Freigabe
- [ ] Global Saturation Gate implementieren
- [ ] SSE Keepalive-Buffer implementieren
- [ ] hold_timeout_ms=15000 implementieren
- [ ] Unit Tests

## Historie

- 2026-09-10 Defiant: Task erstellt, Vorab-Diagnose
- 2026-09-10 Enterprise: Task uebernommen, blocked auf Scotty
- 2026-09-10 Defiant: Keepalive-Buffer Assessment
- 2026-09-10 Praetor: Entscheidung hold=15s max, Saturation Gate beide Pfade
- 2026-09-10 Enterprise: Analyse-Update bestaetigt, Praetor-Fragen weitergeleitet

- 2026-09-10T10:57:29Z Enterprise: completed
