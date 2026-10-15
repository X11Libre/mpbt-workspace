---
title: "Investigate/improve model-balancing for dreadnought/bigpickle quota limits"
category: parked
kind: "task"
status: "open"
assigned-to: "—"
tags: "starfleetctl,model-proxy,balancing,post-release"
---

## Problem

Heute: `bigpickle` (zen-proxy free-tier) lief in **quota-limit** (429 Too Many Requests). Das balancing der Strategie `heavy-model` / `dreadnought` (Member: big-pickle Prio 1, Nemotron Ultra Prio 2, Nemotron Super Prio 3) scheint **nicht korrekt wegzugeschaltet** zu haben, sondern blieb bei bigpickle hängen → haufenweise 429 für die Flotte.

Vermutete Ursachen:
- `fallback`-Strategie prüft nur Fehler beim Aufruf, aber 429 (Rate Limit) wird möglicherweise **nicht** als fallbarer Fehler klassifiziert (oder gar nicht erst als Fehler erkannt, sondern als "Retry" intern behandelt ohne Fallback).
- `x-opencode-request` / Session-Affinity-Header: wenn `big-pickle` 429 liefert, aber die Session-ID weiterhin gesendet wird, landet der nächste Request wieder beim selben Endpunkt, statt zu failovern.
- Die `fallback`-Logik in der Strategie (model-proxy) muss nachgemessen werden: welche Fehler-Codes / Klassifizierungen lösen Fallback aus?

## Ziel (nach Release)

1. **Balancing-Logik härten**: 429 (Rate Limit) muss explizit als Fallback-Trigger klassifiziert werden — nicht nur als transient-retry.
2. **Session-Affinity bei Fallback**: bei Fallback muss `x-opencode-session` / Affinity neu gesetzt werden, damit der nächste Request nicht wieder am selben limitierten Endpunkt landet (Proxy muss neue Session-ID generieren oder weiterleiten).
3. **Quota-Tracking pro Endpunkt**: optional: pro-Endpunkt Quota-Counter im Proxy, der präventiv wechselt bevor 429 kommt.
4. **Tests**: Chaos-Test mit simulierten 429 auf big-pickle → Fallback auf Nemotron prüfen.

## Kontext / Messwerte (heute)

- Model: `heavy-model` (Dreadnought), Fallback-Reihenfolge: big-pickle (zen-proxy) → Nemotron Ultra (nvidia-direct) → Nemotron Super (nvidia-direct).
- Symptom: Flotte bekommt 429 von big-pickle, wechselt **nicht** automatisch weg → Requests schlagen fehl oder hängen, bis man manuell Modell wechselt (wie hier: `nim-first` manuell gesetzt).
- Balancing-Code: in model-proxy `strategy/fallback.go` (verm.) — beim Umsetzen genau ansehen.

## Owner / Timing

- **Nach Release** (Praetor-Vormerkung).
- Owner: starfleetctl/model-proxy (LaForge/Enterprise).
- Abhängigkeit: evtl. Änderung in model-proxy config + Code (Strategy-Interface).
