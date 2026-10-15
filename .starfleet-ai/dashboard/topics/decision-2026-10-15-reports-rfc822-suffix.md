---
title: "DECISION: Reports bleiben RFC822 — nur Dateisuffix .json korrigieren"
category: active
kind: "decision"
status: "active"
assigned-to: "Enterprise"
tags: "decision,reports,starfleetctl"
---

## Entscheidung

**Praetor, Console 2026-10-15:** Reports bleiben im **RFC822-Format** —
nur der Dateisuffix `.json` wird korrigiert. Kein Rückbau zu echtem JSON.

Der `.json`-Suffix ist ein Artefakt der früheren JSON→RFC822-Umstellung
(Code-Fundstelle: `internal/reports/store.go:40`, plus Kommentar `:5`).

## Auslöser

Defiant-Messung (m4514) an Enterprise: Report-Files tragen `.json`, sind aber
RFC822 (`Message-ID:`/`Date:`/`From:`/`Subject:`); Doku+Kommentare falsch.

## Betroffen / Umsetzung

- **Owner:** Enterprise (starfleetctl-Source-Claim, m1339; LaForge offline)
- **Doku/Kommentar-Fixes:** laufen in Enterprise-Zug mit (m4518)
- **Noch offen (Detail):** Suffixwahl `.eml` vs. `.rfc822`; Migration der
  5 Altdateien in `.starfleet-ai/var/reports/`
- **Noch offen (separat):** ob `internal/reports` einen expliziten
  Git-commit/push-Pfad bekommt (wie `dashboard topic commit`)

## Verbreitung

- Broadcast: m4522 (alle Schiffe, Ack-Pflicht per Standing-Regel)
- Direktübergabe: m4523 an Enterprise
