Title: "Model-API Infrastruktur blockiert: NIM saturiert, Zen-Credits leer"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: "2026-09-09T09:54:47Z"
Doc-Ref: "—"

NVIDIA-NIM-Upstream antwortet massenhaft mit HTTP 429 (Rate-Limit/Saturation); selbst Test-Requests haengen. zen-proxy (OpenCode Zen) liefert CreditsError: Workspace wrk_01KTKTCQ06G0YCTM7VJ6WYPT0Q hat keine Zahlungsmethode, Free-Tier-Credits aufgebraucht. Flagschiff-Status: beide Pfade blockiert. Ship-Sessions von Gowron/Voyager auf blocked gesetzt (per Comms angewiesen). Aktionsbedarf: Entscheidung Praetor - Zahlungsmethode hinterlegen oder NIM-Quota pruefen.

- 2026-09-09T09:55:10Z Enterprise: progress 10% (Diagnose abgeschlossen: (1) NIM-Upstream saturiert (massenhaft 429, Test-Requests haengen). (2) zen-proxy liefert CreditsError - Workspace wrk_01KTKTCQ06G0YCTM7VJ6WYPT0Q ohne Zahlungsmethode, Free-Tier-Credits leer. Beide Pfade blockiert. Modell-Proxy neu gestartet (pid 29730, Header-Stamp aktiv). Voyager/Gowron via Comms auf blocked gesetzt. Blockiert auf Praetor-Entscheidung: Zahlungsmethode hinterlegen oder NIM-Quota pruefen. --status blocked)

- 2026-10-15T11:32:24Z Enterprise: ERLEDIGT (Praetor 2026-10-15): Blocker aktuell nicht vorhanden. Ursache war der Zen-free-tier-Header-Bug (gefixt 629e115/bde09ae/f267f92), nicht die Zahlungsmethode. Verifikation: model-proxy live (fa7d57b) liefert 200 fuer big-pickle (E2E). Bei Wiederauftreten neu aufmachen.
