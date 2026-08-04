---
status: parked
category: parked
created: 2026-08-04
created-by: Defiant
tags: [starfleetctl, deployment, path]
---

## Parked: stale starfleetctl binary in ~/go/bin

Enterprise-Fund (2026-08-04): altes starfleetctl-Binary unter `~/go/bin/starfleetctl`
(Stand 23. Jul, kennt noch `agent-bus` statt `sop`). Ships, die nacktes `starfleetctl`
aufrufen, kriegen DAS und nicht das Workspace-Binary
(`.starfleet-ai/bin/starfleetctl`) — aktuell Ursache eines comms-Problems bei Pasteur.

Folge-Topic: entscheiden ob löschen, Alias/Shim oder PATH-Hinweis in die Ship-Launcher.
