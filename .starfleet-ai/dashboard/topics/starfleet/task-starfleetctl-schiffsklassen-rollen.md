Subject: "starfleetctl: schiffsklassen / rollen"
Category: starfleet
Kind: "task"
Status: "done"
From: "McKinley"
Date: "2026-09-08T11:55:26Z"
Doc-Ref: "—"

Neue metadaten für schiffe: Schiffsklasse (Text/Name)

jedes schiff soll auch eine klassenbezeichnung tragen, die etwas über einsatzweck / grpße aussagt. zb. können für kleinere dinge wie web-scans kleine scouts eingesetzt werden (die mit kleinen schnellen modellen laufen). beim start (auch per web) kann die klasse angegeben werden. fürs web sollen einige namen vorconfigurierbar zur auswahl stehen. die klasse soll dann auch im comms/board als eigenes feld erscheinen. andere schiffe können das dann in der kommunikation sehen (das jeweilige schiff auch selbst, zb. bei initialisierung) - später kann dann zb. via SOPs festgelegt werden, wie aufgaben verteilt werden.

- 2026-09-10T09:55:28Z Enterprise: completed
- 2026-09-17T17:30:00Z Scotty: **IMPLEMENTIERT** — Ship Classes vollständig implementiert:
  - `internal/comms/json.go`: `BoardEntryJSON` hat `Class` Feld, `apiBoard` füllt es aus `StatusRecord.Class`
  - `internal/web/web.go`: Launch-Form hat Template-Dropdown (`ns_template`), lädt Templates via `/api/templates`
  - `internal/web/index.html`: Board UI zeigt Class Badge (`🏷`), Template-Dropdown im Launch-Form
  - `internal/config/templates.go`: `ShipTemplate` struct mit `Name`, `Description`, `Model`, `SessionType`, `ApplyToLaunchOpts` setzt Class
  - Vordefinierte Templates: `scout`, `cruiser`, `heavy` in `.starfleet-ai/conf/templates/templates.yaml`
  - Build: `make` grün
