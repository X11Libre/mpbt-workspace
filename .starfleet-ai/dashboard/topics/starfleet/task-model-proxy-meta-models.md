# Model-Proxy Meta-Models — klassenbasiertes Model-Routing mit Fallback/Round-Robin

## Status
- **Created:** 2026-09-09
- **Created-By:** Defiant
- **Assigned-To:** —
- **Status:** open
- **Category:** active
- **Kind:** task
- **See-Also:** starfleet/task-agent-templates-schiffsklassen (Schiffsklassen-Templates)

## Zusammenfassung

Der Model-Proxy bekommt eine neue Schicht: **Meta-Models** (Model Strategies).
Ein Meta-Model ist eine benannte Auswahlregel für Modelle, die der Agent nie
direkt sieht — er spricht nur das Meta-Model an, der Proxy handelt die
Strategie ab (Fallback, Round-Robin, Weighted).

## Design-Entscheidungen (2026-09-09)

### Session-ID
- Client-Session-Id wird IMMER an den tatsächlichen Upstream durchgereicht
- Egal welches Modell tatsächlich angesprochen wird
- Cache-Affinität bleibt erhalten (wie opencode es direkt tun würde)

### Modell-Kompatibilität
- Modelle sind üblicherweise kompatibel (manuell getestet)
- System-prompt/parameters werden durchgereicht

### Monitoring/Heuristiken
- Konfigurierbar: globale Defaults + per-Strategy Override
- Metriken: Latenz, Fehlerrate, Token-Durchsatz, Consecutive Failures

### Context-Window-Management (Kern-Design)
- **Proxy berechnet `min(context_window)` über alle Modelle in der Strategie**
- Dieses Limit wird opencode via `X-Context-Limit` Header mitgeteilt
- opencode treated dies als effektives Context-Limit
- Compaction wird IMMER vor Erreichen des kleinsten Modells getriggert
- Kein Abhängig davon welches Modell gerade aktiv ist

---

## Teil 1: Strategie-Definitionen

```yaml
strategies:
  heavy-model:
    description: "Komplexe Aufgaben — erst BigPickle, dann Fallback"
    default-model: big-pickle
    models:
      - id: big-pickle
        provider: nim-proxy
        context-window: 131072
        priority: 1
      - id: nvidia/nemotron-3-ultra-550b-a55b
        provider: nim-proxy
        context-window: 32768
        priority: 2
    strategy: fallback
    # Effektives Limit: min(131072, 32768) = 32768

  cruiser-model:
    description: "Allgemeine Arbeit — Round-Robin für Verfügbarkeit"
    models:
      - id: nvidia/nemotron-3-ultra-550b-a55b
        provider: nim-proxy
        context-window: 32768
        weight: 1
      - id: nvidia/nemotron-3-nano-30b-a3b
        provider: nim-proxy
        context-window: 16384
        weight: 1
    strategy: round-robin
    # Effektives Limit: min(32768, 16384) = 16384

  scout-model:
    description: "Leichte Aufgaben — schnell, billig"
    models:
      - id: nvidia/nemotron-3-nano-30b-a3b
        provider: nim-proxy
        context-window: 16384
    strategy: single
    # Effektives Limit: 16384
```

### Strategien-Typen

| Strategie     | Verhalten                                           |
|---------------|-----------------------------------------------------|
| `single`      | Nur ein Modell, kein Fallback                       |
| `fallback`    | Sequenz nach `priority` (niedriger = zuerst)        |
| `round-robin` | Gleichmäßig wechseln                                |
| `weighted`    | Nach `weight`-Faktor                                |

---

## Teil 2: Context-Window-Management (Detail)

### Problem-Szenario

```
1. Session startet mit BigPickle (128k Context)
2. Session wächst auf 80k Tokens
3. BigPickle wird unverfügbar (Quota aufgebraucht)
4. Proxy wechselt auf Nemotron Ultra (32k Context)
5. 80k Tokens > 32k Limit → Upstream lehnt ab
6. Compaction auf Nemotron Ultra: 80k zu verarbeiten → möglicherweise zu groß
7. Session steckt fest
```

### Lösung: Min-Limit von Anfang an

```
1. Strategie "heavy-model" definiert:
   - BigPickle: 128k
   - Nemotron Ultra: 32k
2. Proxy berechnet: effective_limit = min(128k, 32k) = 32k
3. Proxy sendet an opencode: X-Context-Limit: 32768
4. opencode behandelt 32k als hartes Limit
5. Compaction wird bei ~27k getriggert (32k - buffer)
6. Bei Fallback auf Nemotron Ultra: Context passt immer
```

### Vorteile

- **Sicher:** Context ist IMMER kompatibel mit allen Modellen in der Strategie
- **Transparent:** opencode merkt den Wechsel nicht
- **Einfach:** Keine dynamische Limit-Anpassung nötig
- **Compaction funktioniert:** Immer genug Luft für Summary

### Nachteile

- **Verschwendung:** BigPickle's 128k werden nicht ausgenutzt
- **Konservativ:** Nutzer könnte mehr Context haben

### Abwägung

Für unsere Fleet-Nutzung überwiegen die Vorteile:
- Ships arbeiten meistens autonom (Hintergrund)
- Sicherheit > maximale Context-Ausnutzung
- Nutzer kann bei Bedarf manuell mit `--model big-pickle` starten (ohne Strategie)

---

## Teil 3: Implementierung im Proxy

### Context-Window-Berechnung

```go
func (r *Router) EffectiveContextLimit(strategy string) int {
    s := r.strategies[strategy]
    minCtx := math.MaxInt32
    for _, m := range s.Models {
        if m.ContextWindow < minCtx {
            minCtx = m.ContextWindow
        }
    }
    return minCtx
}
```

### Header-Injection

```go
func (r *Router) RoundTrip(req *http.Request) (*http.Response, error) {
    strategy := r.resolveStrategy(req)
    if strategy != "" {
        limit := r.EffectiveContextLimit(strategy)
        req.Header.Set("X-Context-Limit", strconv.Itoa(limit))
    }
    return r.upstream.RoundTrip(req)
}
```

### opencode-Integration

```json
// opencode.json — Context-Limit aus Header lesen
{
  "agent": {
    "context": {
      "source": "header",
      "header": "X-Context-Limit"
    }
  }
}
```

Oder: Proxy sendet das Limit als ersten Response-Header, opencode liest es bei Session-Start.

---

## Teil 4: Circuit Breaker + Session-Affinität

### Affinität
- Default: gleiche Session → gleiches Modell (Cache-Shard)
- Fallback bricht Affinität temporär
- Session-ID wird konsistent an Upstream durchgereicht

### Circuit Breaker (Netflix-Style)

```
Zustände:
  CLOSED    → normal, Affinität aktiv
  OPEN      → Modell geskippt, Fallback aktiv
  HALF-OPEN → nach Cooldown 1 Request testen

Transition:
  CLOSED  → OPEN:      bei Schwellenwert-Überschreitung
  OPEN    → HALF-OPEN: nach cooldown
  HALF-OPEN → CLOSED:  bei Erfolg
  HALF-OPEN → OPEN:    bei erneutem Fehler
```

### Heuriken (konfigurierbar: global + per Strategy)

| Metrik              | Schwellenwert (Default) | Aktion                    |
|---------------------|-------------------------|---------------------------|
| Latenz p95          | > 30s                   | Affinität 1 Request brechen|
| Fehlerrate          | > 20% in 5min          | Circuit Breaker OPEN      |
| Token-Durchsatz     | < 10 tokens/s          | Modell-Wechsel            |
| Consecutive Failures| ≥ 3                     | Sofortiges Skip           |

---

## Teil 5: Trigger-Regeln

```yaml
triggers:
  rate-limited:
    action: skip
    cooldown: 60s
    after: 3 retries

  quota-exhausted:
    action: skip
    cooldown: 3600s
    auto-recover: true

  timeout:
    action: skip
    cooldown: 30s
    max-consecutive: 3

  error:
    action: skip
    cooldown: 10s
```

---

## Teil 6: Provider-Health

```yaml
providers:
  nim-proxy:
    base-url: http://127.0.0.1:8443/v1
    health-check:
      interval: 30s
      timeout: 5s
      endpoint: /v1/models

  zen-proxy:
    base-url: http://127.0.0.1:8443/v1
    health-check:
      interval: 60s
```

---

## Teil 7: Routing-Tabelle

```yaml
routing:
  heavy-model: heavy-model
  cruiser-model: cruiser-model
  scout-model: scout-model
  balanced-model: balanced-model
```

---

## Offene Punkte

1. **Weighted-Round-Robin:** Nach Request-Zahl oder Zeitfenster?

2. **Monitoring-Endpoint:** `/v1/meta-models/status` für aktuelle Strategie + Fallback-Historie

3. **Context-Limit-Header:** Wie genau soll opencode das Limit lesen?
   - Option A: Erster Response-Header bei Session-Start
   - Option B: `/v1/models` Endpoint erweitert um `context_window`
   - Option C: separater Endpoint `/v1/strategy/<name>/limits`
