Title: "starfleetctl: plugin_version wird nie persistiert (dispatch/health/commands Write-Pfad fehlt)"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "LaForge"
Created-By: "Discovery"
Created: "2026-10-10T11:29:41Z"
Doc-Ref: "—"

Gemeldet von Discovery 2026-10-10. Das Feld StatusRecord.PluginVersion (internal/comms/records.go:46) wird in /api/ships exponiert (internal/web/web.go:1621/1636), aber NIE geschrieben. Der opencode-plugin sendet plugin_version, die Go-Seite verwirft es: dispatchRequest (internal/comms/dispatch.go, Struct top) hat kein PluginVersion-Feld und reicht kein --plugin-version durch; health.go Record-Literal (~421-453) und commands.go (~201-225) setzen PluginVersion nie (auch nicht aus prev.). Folge: alle Schiffe melden plugin_version leer; /api/ships + Heartbeat ohne Feld. Evidenz (deployed binary): dispatch health mit plugin_version=2.5.7-TEST gesendet -> nicht persistiert. Fix: PluginVersion in dispatchRequest + in beide Record-Builder (inkl. prev-Preserve). Owner: LaForge. Test danach: dispatch health mit plugin_version senden und in var/comms/status/<ship>.json pruefen.

- 2026-10-15T11:27:42Z Enterprise: VERIFIZIERT ERLEDIGT (Enterprise): plugin_version wird persistiert — dispatchRequest.PluginVersion (dispatch.go:28) + --plugin-version (dispatch.go:223) + health.go:456 coalesce(pluginVersion, prev). Live: var/comms/status/*.json (5/5 Schiffe) tragen plugin_version, z.B. Enterprise=2.5.11.
