Title: "starfleetctl docs: dashboard topics Pfad korrigieren (.starfleet-ai/dashboard/topics statt .starfleet-ai/var/dashboard/topics)"
Category: active
Kind: task
Status: open
Created-By: Defiant
Created: 2026-07-31T08:43:27Z
Assigned-To: —
Doc-Ref: "—"
Slug: dashboard-docs-topics-path

Doku nennt als Topic-Speicherort .starfleet-ai/var/dashboard/topics/, der Code (internal/dashboard/topic.go:50 TopicsDir) nutzt aber .starfleet-ai/dashboard/topics (ohne var) — Doku ist veraltet. Betroffen: starfleetctl/doc/dashboard.md:14, doc/hooks.md:36, doc/USER.md:130, doc/architecture.md:38 (+ evtl. SKILL.md-Fragmente). Index .starfleet-ai/var/DASHBOARD.md ist korrekt. Zugehörig: die relativen Refs in DASHBOARD.md (dashboard/topics/<slug>.md) zeigen relativ zur Index-Position ins Leere — pruefen ob gewollt. NICHT vor Abschluss der laufenden starfleetctl-Arbeit von Enterprise abarbeiten (immer nur 1 Schiff gleichzeitig am starfleet-source).
