---
title: "DECISION: Reports bleiben RFC822 — Suffix wird .eml"
category: active
kind: "decision"
status: "active"
assigned-to: "Enterprise"
tags: "decision,reports,starfleetctl"
---

## Entscheidung

**Praetor, Console 2026-10-15:** Reports bleiben im **RFC822-Format** —
der falsche Dateisuffix `.json` wird zu **`.eml`** geändert.
Kein Rückbau zu echtem JSON.

Der `.json`-Suffix ist ein Artefakt der früheren JSON→RFC822-Umstellung
(Code-Fundstelle: `internal/reports/store.go:40`, plus Kommentar `:5`).

**Suffix ist last-bearing** (gemessen von Voyager, m4542): der Loader
enumeriert per `HasSuffix`/`TrimSuffix(".json")` — der Suffix ist die
Unterscheidung, nicht Beiwerk. Prätor-Begründung für echten Suffix statt
keinem: spätere Status-Files im selben Verzeichnis brauchen die
Unterscheidbarkeit.

## Auslöser

Defiant-Messung (m4514) an Enterprise: Report-Files tragen `.json`, sind aber
RFC822 (`Message-ID:`/`Date:`/`From:`/`Subject:`); Doku+Kommentare falsch.

## Betroffen / Umsetzung

- **Owner:** Enterprise (starfleetctl-Source-Claim, m1339; LaForge offline)
- **Doku/Kommentar-Fixes:** laufen in Enterprise-Zug mit (m4518)
- **Umgesetzt wird:** Suffix `.json` → `.eml` in `internal/reports/store.go`
  (Path/HasSuffix/TrimSuffix), Doku `doc/reports.md` (Pfad, Format, Suffix),
  Kommentare `store.go:5`/`:24`; Migration der 5 Altdateien in
  `.starfleet-ai/var/reports/` (Voyager bietet Skript-Hilfe an, m4527 —
  erst nach Auflösung des Source-Claims)
- **Noch offen (separat):** ob `internal/reports` einen expliziten
  Git-commit/push-Pfad bekommt (wie `dashboard topic commit`)

## Verbreitung

- Broadcast: m4522 (alle Schiffe, Ack-Pflicht per Standing-Regel)
- Verfeinerung .eml: m4542 (Voyager), Acks: Enterprise (m4518/m4523),
  bigpickle-test (m4524), Voyager (m4527/m4542)
- Direktübergabe: m4523 an Enterprise
