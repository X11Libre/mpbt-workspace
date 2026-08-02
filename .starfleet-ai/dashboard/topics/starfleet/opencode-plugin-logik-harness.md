Title: "starfleetctl: opencode-plugin: Logik-Harness/Unit-Test fuer comms-dispatch (execSync-Mock, --dry-run, Crash-Test)"
Category: active
Kind: "task"
Status: "open"
Created-By: "Enterprise"
Created: "2026-07-31T13:43:37Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: opencode-plugin-logik-harness

Nachfolger von m9582 (check-plugin via esbuild+tsc ist done). Optionale Vertiefung: kleiner Harness/Unit-Test der Plugin-Logik in fragments/opencode-plugins/starfleet-dispatch.ts, analog scripts/check-opencode-plugin.sh und optional als weiteres make-Ziel. Vorschlaege aus dem Vorgaenger-Topic: (1) comms-dispatch-Logik mit gemockten execSync/starfleetctl-Calls testen (BUS-Umgebung nachstellen, aufgerufene Argumente pruefen); (2) evtl. --dry-run-Flag im Plugin (nur zeigen, nicht senden); (3) plugin-crash-test: ungueltige/malformed JSON-RPC-Nachrichten und fehlende Felder muessen sauber abgefangen werden statt die agent-session zum Absturz zu bringen. Hinweise: bootstrap-check (checks.go verifyOpencodePlugins) vergleicht deploytes Plugin byte-identisch — nur fragments/opencode-plugins/ editieren; tsconfig fuer den Typ-Check liegt dort bereits. Constraint wie immer: nur 1 Schiff gleichzeitig am starfleet-source — erst starten, wenn kein anderes Schiff daran arbeitet.
