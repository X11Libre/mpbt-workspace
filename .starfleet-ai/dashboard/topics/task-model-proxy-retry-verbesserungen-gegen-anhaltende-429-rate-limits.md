Title: "Model-Proxy: Retry-Verbesserungen gegen anhaltende 429-Rate-Limits"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Enterprise"
Created-By: "Defiant"
Created: ""
Doc-Ref: ""

# Model-Proxy: Retry-Verbesserungen gegen anhaltende 429-Rate-Limits

## Problem

Der aktuelle Proxy-Retry-Mechanismus (MaxRetries=3, RetryDelayMS=1000, fixes Backoff) reicht bei anhaltendem Rate-Limit nicht aus. Die Folge: opencode erschöpft seine eigenen Retries und generiert synthetische Restarts (neuer Turn, neuer Context).

**Research-Ergebnis (Defiant):**
- opencode: `maxRetries = 8` (hardcoded, nicht konfigurierbar), exponentielles Backoff 2s→307s
- Proxy: `MaxRetries=3`, `RetryDelayMS=1000` (fixes Delay, kein exponentielles Backoff)
- Plugin: synthetischer Restart nach Erschöpfung aller Retries
- **Lücke:** Proxy gibt zu früh auf → opencode's 8 Retries werden verbraucht → synthetischer Restart

## vorgeschlagene Lösung: HTTP-Keepalive-Buffer (Gemini-Vorschlag)

**Kernidee:** Der Proxy hält die HTTP-Verbindung zu opencode offen (keepalive) und retryt im Hintergrund, bis der Request klappt. opencode sieht nie einen Fehler — sein 8-Retry-Limit wird gar nicht verbraucht.

```
opencode → Request → Proxy
                        ↓
                  Hält Response-Verbindung offen (HTTP/1.1 keepalive)
                  Retryt im Hintergrund (eigenes Retry-Budget)
                        ↓
                  Erfolg? → Response an opencode (transparent)
                  Timeout? → Erst DANN 429 an opencode
                  Inzwischen: transparenter Model-Switch möglich
```

### Vorteile
- opencode's hardcoded `maxRetries=8` wird **nie verbraucht**
- Proxy hat eigenes, konfigurierbares Retry-Budget (minutenlang)
- Während des Haltens: **transparenter Model-Switch** (Fallback/Load-Balancing) möglich
- Kein synthetischer Restart nötig bei vorübergehender Sättigung

### Konfiguration (vorgeschlagen)

```yaml
# model-proxy.yaml
providers:
  - id: nim-proxy
    # Bestehende Retries (bleiben für schnelle Fehler)
    max_retries: 3
    retry_delay_ms: 1000
    
    # NEU: Keepalive-Buffer für anhaltende 429
    hold_timeout_ms: 60000      # 60s Verbindung halten (default)
    hold_retry_delay_ms: 2000   # 2s zwischen Hintergrund-Retries
    hold_max_retries: 30        # max 30 Retries im Hintergrund (= 60s / 2s)
    
    # NEU: Exponentielles Backoff im Hold-Modus
    hold_backoff: true          # ab 3. Folge-429 exponentiell (2s→4s→8s)
    hold_backoff_start: 3       # erst ab 3. aufeinanderfolgendem 429
    hold_backoff_max_ms: 16000  # maximales Backoff-Intervall
    
    # NEU: Retry-After vom Upstream respektieren
    respect_retry_after: true   # Retry-After Header > eigenes Delay
```

### Implementierung (Pseudocode)

```go
func (p *Proxy) forwardChatHold(w http.ResponseWriter, r *http.Request, ...) {
    // Flusher für Keepalive-Tracking
    flusher := w.(http.Flusher)
    
    // Initialen Request senden
    resp, err := upstreamClient.Do(req)
    
    if err != nil || transientStatus(resp.StatusCode) {
        // === HOLD-MODUS: Verbindung offen lassen ===
        w.Header().Set("Content-Type", "text/event-stream")
        w.Header().Set("Connection", "keep-alive")
        w.WriteHeader(http.StatusOK) // Status 200 senden (noch kein Fehler)
        flusher.Flush()
        
        // Keepalive-Ping alle 15s (verhindert TCP-Timeout)
        ticker := time.NewTicker(15 * time.Second)
        defer ticker.Stop()
        
        holdStart := time.Now()
        retryCount := 0
        
        for {
            select {
            case <-ticker.C:
                // Keepalive-Ping an opencode senden
                fmt.Fprintf(w, ": keepalive\n\n")
                flusher.Flush()
                
            case <-time.After(holdRetryDelay):
                retryCount++
                
                // Retry im Hintergrund
                resp, err = upstreamClient.Do(buildRetryReq())
                
                if err == nil && !transientStatus(resp.StatusCode) {
                    // Erfolg! Response an opencode weiterleiten
                    pipeSSE(w, resp, ...)
                    return
                }
                
                // Retry-After respektieren
                if respectRetryAfter && resp.Header.Get("Retry-After") != "" {
                    // warten...
                }
                
                // Exponentielles Backoff ab hold_backoff_start
                if holdBackoff && retryCount >= holdBackoffStart {
                    delay = min(holdRetryDelay * 2^(retryCount-holdBackoffStart), holdBackoffMaxMs)
                }
            }
            
            // Timeout erreicht? -> DANN 429 an opencode
            if time.Since(holdStart) > holdTimeout {
                sendError(w, 429, "Upstream rate limit exceeded after hold timeout")
                return
            }
        }
    }
    
    // Normaler Pfad (kein Hold nötig)
    pipeSSE(w, resp, ...)
}
```

### Integration mit Model-Switching

Während des Hold-Modus kann der Proxy **transparent auf ein anderes Upstream-Modell umschalten**:

```go
// Im Hold-Modus: Fallback-Modell versuchen
if retryCount > 5 && p.hasFallbackModel(model) {
    fallbackModel := p.getFallbackModel(model)
    log.Printf("hold-mode: switching from %s to %s", model, fallbackModel)
    req = rewriteModel(req, fallbackModel)
}
```

## Praetor-Entscheidung (2026-09-10, via Enterprise/m100175)

1. **Verbindungs-Hold: JA, aber konservativ** — `hold_timeout_ms=15000` als Default UND Maximum (kein 30s/60s). Keepalive-Buffer nur für `stream:true`-Requests, NIM als erste Instanz, Zen default aus.
2. **Global Saturation Gate: BEIDES** — der Cooldown greift für ALLE neuen Requests zu einem gesättigten Provider (normaler Retry-Pfad UND Hold), gebündelt hinter einem Retry-After-respektierenden Timer. Damit ist die 24-parallele-Retry-Amplifikation (8 opencode × 3 proxy) für beide Pfade ausgeschlossen.

Damit sind die unterstehenden offenen Fragen wie folgt entschieden.

## Offene Fragen (ENTSCHEIDEN)

1. **Soll der Hold-Modus für ALLE Provider gelten oder nur für bestimmte?** → Nur NIM anfangs, weitere per Config-Flag. (ENTSCHEIDEN)
2. **Keepalive-Ping-Format?** → SSE-Kommentar `: keepalive\n\n` (Go-Scanner ignoriert Kommentare). (ENTSCHEIDEN: SSE-Kommentar)
3. **Übergang Hold-Modus ↔ normaler Retry?** → Erst proxy-`max_retries` (3) erschöpfen, dann Hold bis `hold_timeout_ms`, danach finaler 429 an opencode (dessen 8-Retry-Raum bleibt erhalten). (ENTSCHEIDEN: so)
4. **Hold-Timeout pro Provider?** → Ja, konfigurierbar; Default 15000ms, Max 15000ms. (ENTSCHEIDEN: ja)

## Nächste Schritte

1. Scotty schließt aktuellen starfleetctl-Task ab
2. Proxy-Code in `internal/modelproxy/proxy.go` erweitern
3. Config-Parser in `internal/modelproxy/config.go` anpassen
4. Tests in `internal/modelproxy/proxy_test.go` ergänzen
5. Deploy via `starfleet-bootstrap`

- 2026-09-10T09:37:18Z Enterprise: Enterprise-Assessment zum Keepalive-Buffer (Gemini-Vorschlag von Defiant): (1) Hold nur bei stream:true gaten, sonst Body-Korruption; (2) Global-Saturation-Gate noetig, sonst Thundering-Herd/Amplifikation (jeder held Request retryt einzeln); (3) Model-Switch waehrend Hold default AUS, opt-in pro Provider; (4) offene Fragen beantwortet: per-Provider Hold (NIM zuerst), SSE-Kommentar-Format, Hold beginnt NACH Erschoepfung der Proxy-max_retries, finaler 429 nach hold_timeout; (5) vor Implementierung Praetor fragen ob 60s+ gehaltene Verbindungen OK. Gesteht auf Scotty-Freigabe. Antwort m100168 an Defiant.
