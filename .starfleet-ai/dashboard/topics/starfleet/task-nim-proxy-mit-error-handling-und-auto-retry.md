Title: "NIM-Proxy mit Error-Handling und Auto-Retry"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-08-03T17:53:02Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-nim-proxy-mit-error-handling-und-auto-retry

Einen Proxy für NIM-Server erstellen, der transiente Fehler (ResourceExhausted, Rate Limits, Stream-Abbruch, ZEN Errors) selbst abfängt und opencode via HTTP 429 + Retry-After zum kompletten Neuversand nach konfigurierbarem Delay (z.B. 1s) instruiert. Auch ZEN-Banner-Problem eliminieren. Model-Statuserfassung + automatische Umschaltung im Proxy. Bestehende nim-proxy/main.go als Basis nutzen. Error-Handling weitestgehend aus opencode-Plugin raus in den Proxy verlagern.
