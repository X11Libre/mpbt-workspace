Title: "starfleet: bug: web neues schiff ohne namen errors wegen belegtem namen"
Category: active
Kind: "task"
Status: "done"
Created-By: "McKinley"
Created: "2026-07-31T12:39:45Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: task-bug-starfleet-bug-web-neues-schiff-ohne-namen-errors-wegen-belegtem-namen

# starfleet/task-bug-starfleet-bug-web-neues-schiff-ohne-namen-errors-wegen-belegtem-namen

**Status:** ✅ **done**

**Description:** bug: starfleet: bug: web->neues schiff -> ohne namen -> errors wegen belegtem namen

**Problem:** Wenn man per web neues schiff startet (ohne namen anzugeben), kam es manchmal (sogar mehrfach hintereinander) vor, dass er versucht einen bereits belegten namen zu nehmen, und das gibt dann error in der gui. Nach genug versuchen klappts dann.

**Root Cause:** `AssignName()` in `internal/shipnames/commands.go` prüfte nur ob eine Reservierungs-Datei existiert, aber nicht ob das Schiff tatsächlich noch lebt (gültiger Heartbeat/Status). Bei schnellen Web-Starts gab es einen Race: Reservierungs-Datei existierte schon, aber der Heartbeat war noch nicht geschrieben → nächstes Schiff versuchte den gleichen Namen.

**Lösung:** `AssignName()` prüft nun zusätzlich den comms-Status:
- Lädt alle Status-Dateien aus `.starfleet-ai/var/comms/status/`
- Ein Name ist "frei" wenn: KEINE Reservierung existiert ODER Reservierung existiert aber Status ist "stale" (kein Heartbeat seit >900s oder State != "idle")
- Spiegelt exakt die `comms.Bus.stale()` Logik wider

**Files changed:**
- `internal/shipnames/commands.go` — `AssignName()` mit Status-Check erweitert, `loadStatusMap()` und `isStale()` hinzugefügt

**Verified:** Build + bootstrap passed, deployed.
