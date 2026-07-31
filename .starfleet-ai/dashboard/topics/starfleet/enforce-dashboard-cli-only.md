---
slug: starfleet/enforce-dashboard-cli-only
title: "Enforcement: Dashboard-Zugriff ausschließlich über starfleetctl CLI (permission-deny)"
category: active
kind: task
status: open
created-by: Enterprise
created: 2026-07-31T10:42:06Z
assigned-to: —
doc_ref: "—"
---

Follow-up zum Bug 'enterprise-deletes-topics' (Root Cause: Enterprise hat beim Startup direkt ls/rm auf .starfleet-ai/dashboard/topics/ ausgeführt — CLI-only-Policy verletzt). Die Policy existiert bereits (Agent-Instructions: 'never Read/Edit/Write/Glob/Grep on DASHBOARD.md or dashboard/topics/*.md'), wird aber nicht technisch erzwungen.

Fix-Kandidaten:
- .opencode permission rules / deny-Regeln für Read/Edit/Write/Glob/Grep/rm auf .starfleet-ai/dashboard/topics/** und DASHBOARD.md (bzw. .starfleet-ai/var/DASHBOARD.md)
- Claude agent-permission-hook nachschärfen (fragments/claude-hooks/agent-permission-hook)
- Pre-commit-Hook (STARFLEET_DASHBOARD_COMMIT-Marker) prüfen, ob er greift

Acceptance:
- Kein Agent (auch keine flagship-Startup-Routine) kann Dashboard-Rohdateien direkt lesen/schreiben/löschen
- Alle legitimen Zugriffe laufen über 'starfleetctl dashboard *'
- Lock-Dateien (.#*) werden von keinem Agent angefasst
