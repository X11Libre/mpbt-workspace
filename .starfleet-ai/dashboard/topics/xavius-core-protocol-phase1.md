---
slug: xavius-core-protocol-phase1
title: "Xavius Core Protocol Phase 1 Implementation"
category: feature
status: active
priority: high
created: "2026-10-31"
updated: "2026-10-31"
assignees: [Enterprise, ShipA, ShipB, ShipC, ShipD, ShipE]
tags: [xavius, vulkan, x11, protocol, phase1]
---

## Ziel
Implementation des Xavius Core Protocols (Phase 1): Device Enumeration + Properties (Subopcodes 1-7)

## Subopcodes (aus registries/request-subopcodes.md)
| Subopcode | Name | Ship | Status |
|-----------|------|------|--------|
| 1 | EnumerateDevices | Ship A | 🚀 In Progress |
| 2 | GetDeviceProperties | Ship C | 🚀 In Progress |
| 3 | GetDeviceMemoryProperties | Ship C | 🚀 In Progress |
| 4 | CreateDevice | Ship D (Defiant) | 🚀 In Progress |
| 5 | DestroyDevice | Ship D (Defiant) | 🚀 In Progress |
| 6 | GetDeviceQueue | Ship D (Defiant) | 🚀 In Progress |
| 7 | GetMemoryProperties | Ship E | 🚀 In Progress |

## Wire-Protocol (Ship A)
- Request/Reply wire format in `Xext/xaverius/`
- Dispatch framework für alle Subopcodes
- Wire-Tests: `python3 tools/check-wire-layout.py && python3 tests/test_wire_vectors.py`

## Spec-Sync
- Authoritative spec: `_WORK_/xav/xav-design` branch `docs/restructure-2026-10-21`
- Opcode registry: `registries/request-subopcodes.md` (47 subopcodes total)
- Koordinations-Datei: `IMPLEMENTATION_COORDINATION.md`
- Spec-Sync vor jedem Push: `git pull --rebase origin docs/restructure-2026-10-21`

## Fleet Coordination
- Ships arbeiten autonom in eigenen Worktrees
- Progress via Starfleet Reports
- Comms via McKinley für Entscheidungen/Blocker
- Externe Design-Agent Review via xav-design repo

## Branch-Struktur
- `rfc/xaverius-core-protocol` (Wire Protocol + Dispatch)
- `rfc/xaverius-devices` (Device Enumeration + Lifecycle)

## Verifikation
- Wire-Tests vor jedem Commit
- Spec-Sync vor jedem Push
- External design agent review
