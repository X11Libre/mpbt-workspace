Title: "NIM-Proxy mit Error-Handling und Auto-Retry"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "Interpid"
Created-By: "Enterprise"
Created: "2026-08-03T17:53:02Z"
Doc-Ref: "—"

# NIM-Proxy: Detaillierter Plan

## Ziel
Einen Proxy für NIM-Server erstellen, der transiente Fehler (ResourceExhausted, Rate Limits, Stream-Abbruch, ZEN Errors) selbst abfängt und opencode via HTTP 429 + Retry-After zum kompletten Neuversand nach konfigurierbarem Delay (z.B. 1s) instruiert. Auch ZEN-Banner-Problem eliminieren. Model-Statuserfassung + automatische Umschaltung im Proxy. Bestehende nim-proxy/main.go als Basis nutzen. Error-Handling weitestgehend aus opencode-Plugin raus in den Proxy verlagern.

## Bestehende Basis
Aktuelle `nim-proxy/main.go` (einfacher Pass-Through mit Retry-Signal bei 5xx/Stream-Fehlern):
- HTTP 429 + Retry-After Header für Auto-Retry
- Stream-Validierung (ganzen Body puffern)
- JSON-Fehler-Erkennung im Stream

## Erweiterungen (Plan)

### 1. ZEN-spezifische Fehlererkennung
```go
// In classifyError() ergänzen:
if strings.Contains(bodyStr, "zen-ratelimit") || 
   strings.Contains(bodyStr, "Worker local total request limi") {
    return "zen-ratelimit: Worker local total request limit exceeded", true
}
if strings.Contains(bodyStr, "nim-overload") {
    return "nim-overload: NIM server overloaded", true
}
```

### 2. Model-Statuserfassung (in-memory, REST-API)
```go
type ModelStatus struct {
    Name          string    `json:"name"`
    Server        string    `json:"server"`
    Healthy       bool      `json:"healthy"`
    LastError     string    `json:"last_error,omitempty"`
    LastErrorTime time.Time `json:"last_error_time,omitempty"`
    ErrorCount    int       `json:"error_count"`
    LastSuccess   time.Time `json:"last_success,omitempty"`
}

// Endpoints:
// GET /models          → alle Model-Status
// GET /models/<name>   → Status eines Models
// GET /health          → Proxy-Health + Config
```

Model-Name/Server via Header aus Request extrahieren:
- `X-Model`, `X-Model-ID` → Model-Name
- `X-Provider`, `X-Provider-ID` → Server

### 3. Automatische Model-Umschaltung (configurable)
```go
// Config via Env:
FALLBACK_MODEL=meta/llama-3.1-70b-instruct
ENABLE_AUTO_SWITCH=true

// Bei Quota/Rate-Limit Fehler:
if enableAutoSwitch && fallbackModel != "" {
    resp.SwitchModel = fallbackModel  // im JSON-Response an opencode
    updateModelStatus(model, server, false, errorDetail)
}
```

### 4. Plugin-Entlastung (was aus Plugin rausgezogen wird)
| Funktion | Bisher im Plugin | Neu im Proxy |
|----------|------------------|--------------|
| ZEN-Rate-Limit Erkennung | Log-Monitor (tail opencode.log) | Stream-Content-Analyse |
| Model-Switch bei Quota | `executeAction(switch-model)` | HTTP 429 + `SwitchModel` Header/Body |
| Retry-Cooldown | `RETRY_COOLDOWN_MS` im Plugin | `Retry-After` Header (einheitlich) |
| Stream-Error-Detection | Log-Monitor + Retry-Poll | Stream-Buffer-Analyse |
| Health/Status-Reporting | `bus({cmd: 'health'})` | `/health`, `/models` Endpoints |

### 5. Response-Format für opencode (erweitert)
```json
{
  "error": "transient_error",
  "retry_after": 1,
  "reason": "zen-ratelimit: Worker local total request limit exceeded",
  "switch_model": "meta/llama-3.1-70b-instruct"
}
```
opencode liest `Retry-After` Header (schon implementiert) + `switch_model` aus Body für Auto-Switch.

### 6. Konfiguration (Env-Vars)
| Variable | Default | Beschreibung |
|----------|---------|--------------|
| `NIM_URL` | `http://localhost:8000` | Upstream NIM Server |
| `PROXY_PORT` | `:8081` | Proxy Listen Port |
| `RETRY_AFTER_SECONDS` | `1` | Retry-After Wert (Sekunden) |
| `PROXY_LOG_FILE` | `proxy.log` | Log-Datei |
| `FALLBACK_MODEL` | `""` | Fallback bei Quota |
| `ENABLE_AUTO_SWITCH` | `true` | Auto-Switch aktivieren |

### 7. opencode-Plugin Anpassungen (nach Proxy-Deploy)
- Log-Monitor (`checkLogForErrors`) → entfernen/vereinfachen (nur noch Fallback)
- Retry-Poll (`pollRetryStatus`) → entfernen (Proxy macht das via 429)
- `executeAction(switch-model)` → entfernen (Proxy signalisiert `switch_model`)
- `error-handle` bus command → nur noch für echte Session-Errors (nicht mehr für Model-API)
- Plugin wird zu: Heartbeat + Comms-Poll + Fleet-Identity + Directive-Injection

## Implementierungs-Reihenfolge
1. **Proxy erweitern** (classifyError, Model-Status, /models, /health, SwitchModel-Response)
2. **Proxy testen** (lokal gegen NIM, simulierte Fehler)
3. **Plugin vereinfachen** (Log-Monitor, Retry-Poll, Model-Switch raus)
4. **Bootstrap & Deploy** (starfleet-bootstrap → timer restart → web restart)
5. **Verifikation** (Dashboard zeigt Plugin-Version, Model-Status via `/models`)

## Beispiel-Requests für Test
```bash
# Normaler Request (via Proxy)
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "X-Model: meta/llama-3.1-70b-instruct" \
  -H "X-Provider: nim" \
  -d '{"model":"meta/llama-3.1-70b-instruct","messages":[{"role":"user","content":"test"}]}'

# Health Check
curl http://localhost:8081/health

# Model Status
curl http://localhost:8081/models
curl http://localhost:8081/models/meta/llama-3.1-70b-instruct
```

# Generalisierung

* soll mit theoretisch allen providern laufen (evtl. spezielle provider-spezifishce behandlung)
* aktuell zu unterstüzten: NIM und ZEN
* soll automatisch (mittels unseres opencode.json generator) ins opencode als eigner provider eingedockt werden - oder wenn möglich als proxy laufe --> prüfe welche option die bessere ist
* soll die gleichen Fehler abfangen wie bisher schon das plugin tut
* neu gestartete schiffe (background und terminal) sollen den proxy automatisch benuzten
* provider-config soll aus der globalen-user-config entnommen werden (achtung da werden auch env-variablen für auth-tokens benutzt)
* erstmal nur zusätzlich zur plugin-logik einbauen - die plugin-logik erstmal so belassten (fallback)
