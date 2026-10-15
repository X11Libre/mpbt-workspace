---
title: "Refactor (post-release): generischer RFC822-Parser/Writer als util-Subpackage"
category: parked
kind: "task"
status: "open"
assigned-to: "—"
tags: "starfleetctl,refactoring,rfc822,post-release"
---

## Auftrag (Praetor, Console 2026-10-15)

**Generischen RFC822-Parser/Writer** bauen: ein generisches Struct mit
zugehoerigen Functions, als **`util/`-Subpackage** im starfleetctl-Source
(z.B. `internal/util/rfc822/`). Danach ueberall dort verwenden, wo wir
RFC822-style Files haben.

**Timing: NACH dem Release** — bis dahin nur vorgemerkt, nicht anfassen.

## Kontext (Entstehung)

Aus dem Reports-Suffix-Vorfall (Decision
`decision-2026-10-15-reports-rfc822-suffix`, m4514/m4522/m4542): Reports
sind RFC822 mit Headers (Message-ID/Date/From/Subject/Tags/Task-Ref) +
Markdown-Body, aktuell mit ad-hoc-Code in `internal/reports/` geparsed und
geschrieben (store.go). Der `.json`-Suffix war Artefakt einer frueheren
JSON->RFC822-Umstellung — mehrere Stellen haben das Format also schon
einmal gewechselt, ohne gemeinsame Schicht.

## Zielbild

- `internal/util/rfc822` (Name offen): generisches Record-Struct
  (Headers-Map + Body) + Parse/Write/Enumerate-Functions
- Header-Zugriff typisiert wo noetig (Message-ID, Date, Subject, …),
  Erweiterbare Header-Map fuer domaenenspezifische (Tags, Task-Ref)
- File-Suffix als Parameter/Option, NICHT in die Kernlogik hardcodiert
  (der .json->.eml-Fall zeigt: der Loader hat den Suffix als
  Unterscheidungs-Merkmal — last-bearing, aber austauschbar)
- Enumerate/Load-Filter (HasSuffix-basiert) gehoert in die Schicht, nicht
  in jeden Consumer

## Erste Consumers (nach dem Umbau)

1. `internal/reports/` (aktueller ad-hoc-Parser, store.go)
2. Pruefen, ob weitere RFC822-style Stellen existieren (z.B. Message-Dumps
   unter var/comms/? — beim Umsetzen messen, nicht raten)

## Offen

- Timing: nach Release, Praetor gibt Freigabe
- Owner: starfleetctl-Source (LaForge-Hoheit; derzeit Enterprise-Claim)
- Package-/API-Design bei der Umsetzung
