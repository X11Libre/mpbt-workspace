---
slug: task-starfleet-plugin-model-server-registrierung-im-web-agent-resume
title: "Starfleet Plugin: Model/Server Registrierung im Web + Agent Resume"
category: active
kind: task
status: open
created-by: Phoenix
created: 2026-07-16T19:04:56Z
assigned-to: —
doc_ref: "—"
---

Plugin-System für starfleetctl: Models und Server registrieren (z.B. für opencode/Claude Code), die im Web-Frontend sichtbar sind. Web-UI: neuer Tab 'Plugins' zeigt registrierte Models/Servers mit Status. Zusätzlich: im Web-Frontend Möglichkeit, Agents wieder fortzusetzen (resume), die durch Error gestoppt wurden (agent-bus status 'blocked' oder 'error'). Backend: agent-bus status prüfen, bei Error/Blocked 'resume' via agent-bus tell oder session restart anbieten. Akzeptanz: Web-Tab 'Plugins' listet Models/Servers; bei Error-gestopptem Schiff Button 'Resume' -> Schiff läuft wieder.
