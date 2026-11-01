---
slug: xavius-phase2-merge-plan
title: "Xavius Phase 2 Final-Merge-Plan"
category: feature
status: active
priority: high
created: "2026-10-31"
updated: "2026-10-31"
assignees: [Enterprise, ShipA, ShipB, ShipC, ShipD, ShipE]
tags: [xavius, vulkan, x11, protocol, phase2, merge-plan]
---

## Ziel
Alle Xavius Phase 2 Subopcode-Branches (8-47) werden am Ende in **einen gemeinsamen Branch** zusammengeführt, bevor ein PR gegen master geöffnet wird.

## Branches (Phase 2)
| Ship | Rolle | Subopcodes | Branch |
|------|-------|------------|--------|
| Ship A | Compute Baseline | 8-15 | rfc/xaverius-compute-base |
| Ship B | Compute Memory | 16-24 | rfc/xaverius-compute-memory |
| Ship C | Compute Lifecycle | 25-33 | rfc/xaverius-compute-lifecycle |
| Ship D | Compute Synchronization | 34-40 | rfc/xaverius-compute-sync |
| Ship E | Presentation | 41-47 | rfc/xaverius-presentation |

## Final-Merge-Verfahren
1. Jeder Ship vollendet seine Subopcodes auf seinem eigenen Branch
2. Enterprise erstellt einen Merge-Branch `rfc/xaverius-phase2-complete` von master
3. Alle 5 Subopcode-Branches werden per `--no-ff` in den Merge-Branch gemergt
4. Wire-Tests + Build `-Dwerror=true` auf dem gemergten Branch verifiziert
5. PR gegen master geöffnet

## Wire-Tests vor jedem Commit (alle Ships)
`python3 tools/check-wire-layout.py && python3 tests/test_wire_vectors.py`

## Spec-Sync vor jedem Push (alle Ships)
`git pull --rebase origin docs/restructure-2026-10-21` im xav-design Repo

## Koordination
- Progress via Starfleet Reports
- Blocker via Comms an Enterprise
- Final-Merge wird von Enterprise koordiniert, wenn alle 5 Ships melden „fertig"
