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

## Aufgelöst (2026-08-04, Enterprise)

- Altes Binary wurde vom Praetor geloescht. `which starfleetctl` zeigt jetzt das
  Workspace-Binary.
- Folgeaufgabe umgesetzt: SOP `working-practices-for-ships.md` haertet Ships darauf,
  immer `.starfleet-ai/bin/starfleetctl` (nie nackt) aufzurufen und bei Ueberraschung
  `which starfleetctl` zu pruefen (starfleetctl master 3936dfe).
- Totes `var/agent-bus/`-Verzeichnis mit 8 nie zugestellten Nachrichten archiviert nach
  `_WORK_/agent-bus-archive-20260804` und entfernt. Stargazer-CI-Payloads daraus waren
  bereits durch Dashboard-Topic `task-fix-ci-failure-in-xserver-build-with-gbm-disabled`
  abgedeckt (keine comms-Migration noetig).
- Ships mit vergiftetem Kontext (Pasteur/Defiant, alte agent-bus-Tool-Calls) per comms
  informiert.
