Title: "starfleetctl: globaler Flotten-Name/Beschreibung im Web-Kopf (lokal konfigurierbar)"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-10T12:04:14Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/task-starfleetctl-globaler-flotten-name-beschreibung-im-web-kopf-lokal-konfigurierbar

Feature-Request Praetor (2026-10-10). Das Web-Frontend soll ganz oben, neben 'Fleet console', einen globalen FLOTTEN-NAMEN (+ optional Beschreibung) anzeigen. Lokal konfigurierbar, damit man auf einen Blick sieht, WELCHE Instanz man vor sich hat.

MOTIVATION: Mit dem neuen isolierten Testbed (eigene Instanz, eigene Ports/var unter _WORK_) gibt es mehrere Web-Frontends parallel. Der Kopf soll die Instanz klar benennen (Live vs. Testbed), damit niemand versehentlich im falschen Frontend arbeitet.

UMSETZUNG (Vorschlag): 
- Config: in .starfleet-ai/conf/fleet.yaml unter fleet: z.B. name: "...", description: "..." (lokal, pro Workspace). Fallback/Default: "Fleet console" (bzw. leer -> kein Zusatz).
- Backend: ueber einen bestehenden API-Endpunkt (z.B. /api/identity oder ein neues /api/fleet-info) ausliefern, inkl. Env-Overrides (z.B. STARFLEET_FLEET_NAME) analog WebAddr/WebShipID.
- Frontend: in internal/web/index.html im Header neben dem Titel rendern.
- Testbed setzt z.B. name: "Testbed".

Akzeptanz: Live-Web zeigt den Live-Namen, Testbed-Web zeigt "Testbed"; konfigurierbar ohne Rebuild; sichtbar ohne Hover.
