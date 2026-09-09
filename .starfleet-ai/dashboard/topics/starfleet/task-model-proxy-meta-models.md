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

## Konfiguration (YAML)

```yaml
# .starfleet-ai/conf/model-strategies.yaml
strategies:
  heavy-model:
    description: "Komplexe Aufgaben — erst BigPickle, dann Fallback"
    models:
      - id: "big-pickle"
        provider: nim-proxy
        weight: 1
      - id: "nvidia/nemotron-3-ultra-550b-a55b"
        provider: nim-proxy
        weight: 1
    strategy: fallback
    fallback-on:
      - quota-exhausted
      - rate-limited
      - timeout

  cruiser-model:
    description: "Allgemeine Arbeit — zwischen Nemotron ultra/3 wechseln"
    models:
      - id: "nvidia/nemotron-3-ultra-550b-a55b"
        provider: nim-proxy
      - id: "nvidia/nemotron-3-nano-30b-a3b"
        provider: nim-proxy
    strategy: round-robin
    fallback-on:
      - rate-limited
      - timeout

  scout-model:
    description: "Leichte Aufgaben — schnell und billig"
    models:
      - id: "nvidia/nemotron-3-nano-30b-a3b"
        provider: nim-proxy
    strategy: single
```

## Strategien

| Strategie     | Verhalten                                           |
|---------------|-----------------------------------------------------|
| `single`      | Nur ein Modell, kein Fallback                       |
| `fallback`    | Erst Modell 1, bei Fehler → Modell 2, etc.         |
| `round-robin` | Wechsel nach jedem Request (oder nach Quota)        |
| `weighted`    | Zufällig nach Gewicht, Schwerpunkt auf erstes       |

## Trigger für Fallback

- `quota-exhausted` — Free-Tier Limit erreicht (z.B. zen-proxy)
- `rate-limited` — 429 von Provider
- `timeout` — Provider antwortet nicht
- `error` — allgemeiner API-Fehler

## Vorteile

- **Agent merkt nichts** — spricht immer dasselbe Meta-Model an
- **Proxy handelt ab** — Fallback/Wechsel komplett transparent
- **Kosteneffizient** — teure Modelle nur wenn nötig, sonst günstigere
- **Verfügbarkeit** — automatischer Wechsel bei Provider-Problemen

## Use Cases

1. **BigPickle → Nemotron Ultra Fallback:** Bei Free-Tier-Aufbrauchen
   schaltet Proxy vollautomatisch auf Nemotron Ultra um. Agent merkt nichts.
2. **Nemotron Ultra ↔ Nano Round-Robin:** Wechselt zwischen beiden für
   bessere Verfügbarkeit bei temporären Blocks.
3. **Scout mit single:** Nano allein, kein Fallback — billig und schnell.

## Integration mit Schiffsklassen

```
Template "Heavy"  → Meta-Model "heavy-model"  → Proxy: BigPickle → (fallback) → Nemotron Ultra
Template "Cruiser"→ Meta-Model "cruiser-model"→ Proxy: Round-Robin ultra/nano
Template "Scout"  → Meta-Model "scout-model"  → Proxy: Nano (single)
```

## Implementierung

1. YAML-Config für Meta-Model-Strategien (`.starfleet-ai/conf/model-strategies.yaml`)
2. Model-Proxy erweitern: Meta-Model-Routing + Fallback-Logik
3. Status/Health-Endpoint für aktuelle Strategie + Fallback-Historie
4. `--model` Flag akzeptiert Meta-Model-Namen (nicht nur echte Modelle)

## Offene Fragen

- Meta-Model-Strategien: pro Provider oder pro Meta-Model?
- Soll Fallback-Historie im Proxy-Log oder als Endpoint sichtbar sein?
- Weighted-Round-Robin: nach Request-Zahl oder nach Zeitfenster?
