Title: "starfleetctl: plugin_version wird nie persistiert (dispatch/health/commands Write-Pfad fehlt)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Discovery"
Created: "2026-10-10T11:29:41Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/bug-plugin-version-never-persisted

Gemeldet von Discovery 2026-10-10. Das Feld StatusRecord.PluginVersion (internal/comms/records.go:46) wird in /api/ships exponiert (internal/web/web.go:1621/1636), aber NIE geschrieben. Der opencode-plugin sendet plugin_version, die Go-Seite verwirft es: dispatchRequest (internal/comms/dispatch.go, Struct top) hat kein PluginVersion-Feld und reicht kein --plugin-version durch; health.go Record-Literal (~421-453) und commands.go (~201-225) setzen PluginVersion nie (auch nicht aus prev.). Folge: alle Schiffe melden plugin_version leer; /api/ships + Heartbeat ohne Feld. Evidenz (deployed binary): dispatch health mit plugin_version=2.5.7-TEST gesendet -> nicht persistiert. Fix: PluginVersion in dispatchRequest + in beide Record-Builder (inkl. prev-Preserve). Owner: LaForge. Test danach: dispatch health mit plugin_version senden und in var/comms/status/<ship>.json pruefen.
