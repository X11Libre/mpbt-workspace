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
- Bei Context-Window-Unterschieden: ggf. Compact-Trigger auslösen
- Noch zu klären: differentielle Behandlung von system-prompt/parameters

### Monitoring/Heuristiken
- Konfigurierbar: globale Defaults + per-Strategy Override
- Metriken: Latenz, Fehlerrate, Token-Durchsatz, Consecutive Failures

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
        priority: 1
      - id: nvidia/nemotron-3-ultra-550b-a55b
        provider: nim-proxy
        priority: 2
    strategy: fallback

  cruiser-model:
    description: "Allgemeine Arbeit — Round-Robin für Verfügbarkeit"
    models:
      - id: nvidia/nemotron-3-ultra-550b-a55b
        provider: nim-proxy
        weight: 1
      - id: nvidia/nemotron-3-nano-30b-a3b
        provider: nim-proxy
        weight: 1
    strategy: round-robin

  scout-model:
    description: "Leichte Aufgaben — schnell, billig"
    models:
      - id: nvidia/nemotron-3-nano-30b-a3b
        provider: nim-proxy
    strategy: single

  balanced-model:
    description: "60% BigPickle, 40% Nemotron Ultra"
    models:
      - id: big-pickle
        provider: nim-proxy
        weight: 3
      - id: nvidia/nemotron-3-ultra-550b-a55b
        provider: nim-proxy
        weight: 2
    strategy: weighted
```

### Strategien-Typen

| Strategie     | Verhalten                                           |
|---------------|-----------------------------------------------------|
| `single`      | Nur ein Modell, kein Fallback                       |
| `fallback`    | Sequenz nach `priority` (niedriger = zuerst)        |
| `round-robin` | Gleichmäßig wechseln                                |
| `weighted`    | Nach `weight`-Faktor                                |

---

## Teil 2: Session-Affinität + Circuit Breaker

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

## Teil 3: Trigger-Regeln

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

## Teil 4: Provider-Health

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

## Teil 5: Routing-Tabelle

```yaml
routing:
  heavy-model: heavy-model
  cruiser-model: cruiser-model
  scout-model: scout-model
  balanced-model: balanced-model
```

---

## Offene Punkte

- [ ] Context-Window-Unterschiede: Compact-Trigger wie implementieren?
- [ ] System-Prompt / Parameters bei Modell-Wechsel: durchreichen oder anpassen?
- [ ] Weighted-Round-Robin: nach Request-Zahl oder Zeitfenster?
- [ ] Monitoring-Endpoint: /v1/meta-models/status für aktuelle Strategie
