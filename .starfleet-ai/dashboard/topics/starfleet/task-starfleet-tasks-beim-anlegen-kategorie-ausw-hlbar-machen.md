---
title: starfleet: tasks: beim anlegen kategorie auswählbar machen
status: done
---

# starfleet/task-starfleet-tasks-beim-anlegen-kategorie-ausw-hlbar-machen

**Status:** ✅ **done**

**Problem:** Beim Erstellen einer neuen Aufgabe im Web-UI gab es kein Auswahlfeld für die Kategorie (active/parked/starfleet). Standard war immer "active".

**Lösung:** 
1. **Web UI (index.html)**: Dropdown `<select id="t_cat">` hinzugefügt mit Optionen "active", "parked", "starfleet" (Default: active)
2. **Backend API (web.go)**: `category` Feld im JSON-Request hinzugefügt
3. **Task Package (task.go)**: 
   - `parseCaptureArgs()` um `--category` Option erweitert
   - `buildTopicFile()` nimmt `category` Parameter entgegen (Default: "active")
   - `RunCaptureOnly()` um `category` Parameter erweitert
4. **Logs Package (logs.go)**: Aufruf von `RunCaptureOnly` angepasst (Default "active")

**Files changed:**
- `internal/web/index.html` — Kategorie-Dropdown im "Neue Aufgabe" Formular
- `internal/web/web.go` — `category` Feld in apiTask Request-Struct
- `internal/task/task.go` — `--category` CLI-Option, `buildTopicFile` + `RunCaptureOnly` erweitert
- `internal/logs/logs.go` — Aufruf angepasst

**Verified:** Build + bootstrap passed (network error on remote pull, local build OK).
