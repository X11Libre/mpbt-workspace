---
slug: starfleet/plugin-status-override-fix
title: "starfleet-dispatch Plugin: Status-Override bei jedem Turn entfernen"
category: active
kind: task
status: assigned
created-by: Defiant
created: 2026-07-31T13:57:38Z
assigned-to: Enterprise
doc_ref: "—"
---

Plugin starfleet-dispatch.ts setzt bei jedem Turn-Start (system.transform Hook) den Status unconditionally auf 'working' (health + status calls). DoInit setzt idle beim Start, aber der Override überschreibt jeden comms status idle. Resultat: Alle opencode-Schiffe (inkl. Enterprise) zeigen nach dem ersten Turn dauerhaft 'working' im Board.

Fix: In fragments/opencode-plugins/starfleet-dispatch.ts den state:'working' aus health-Call und den status-Call im system.transform entfernen. Status gehört wieder dem Modell/Task-Mechanismus (AGENTS.md). Heartbeat (Z. 451) behält Touch-only für Staleness. Auch 3s-Fallback (Z. 545) bereinigen.

Deployment: check-opencode-plugin.sh → commit starfleetctl-Repo (sign-off) → ./starfleet-bootstrap → Status Defiant auf idle setzen.
