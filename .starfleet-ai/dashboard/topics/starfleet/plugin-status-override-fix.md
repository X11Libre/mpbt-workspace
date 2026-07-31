---
title: "starfleet-dispatch Plugin: Status-Override bei jedem Turn entfernen"
category: "starfleet"
status: "done"
---

# starfleet/plugin-status-override-fix

**Status:** ✅ **done**

**Description:** starfleet-dispatch Plugin: Status-Override bei jedem Turn entfernen

**Problem:** Das Plugin sendete bei jedem Turn `bus({ cmd: 'status', state: 'working', note: 'opencode ship' })`, was jeden task-spezifischen Status (wie `task adopt`) sofort überschrieb. Die Fleet sah nur "working / opencode ship" statt des echten Tasks.

**Lösung:** In `fragments/opencode-plugins/starfleet-dispatch.ts` die redundante `status` Meldung aus dem `chat.system.transform` Hook entfernt (Zeile ~642). Der `health` heartbeat reicht für Liveness; `task` Commands setzen den Task-Status separat. Auch den 3s TUI-fallback `state='working'` entfernt.

**Commit:** `4bcefe2` — `starfleet-dispatch: remove forced 'working' state from system.transform health calls`

**Verified:** Build + bootstrap passed, plugin updated.