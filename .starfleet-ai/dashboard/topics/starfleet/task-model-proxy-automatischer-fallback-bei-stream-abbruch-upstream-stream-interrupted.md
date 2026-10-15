Title: "model-proxy: automatischer Fallback bei Stream-Abbruch (upstream stream interrupted)"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "LaForge"
Created-By: "Enterprise"
Created: "2026-10-10T12:29:07Z"
Doc-Ref: "—"

Feature-Request: Wenn ein Streaming-Request abbricht (upstream stream interrupted before [DONE] / socket closed / 429), soll der model-proxy AUTOMATISCH mit dem nächsten Fallback-Model in der Strategy retryen, statt den Request zu failen.

AKTUELL: Stream-Abbruch → Request failed, keine Fallback-Logik.

GEWÜNSCHT: In internal/modelproxy/proxy.go (Stream-Handler) / internal/modelproxy/run.go (Strategy-Execution):
- Auf Stream-Abbruch (EOF vor [DONE] / socket closed / 429 / connection reset) detecten
- Nächstes Model in der Strategy-Pool auswählen (Round-Robin / weighted / etc. je nach Strategy)
- Request transparent neu starten mit nächstem Model (Headers / Body replizieren)
- Max. Retries = Anzahl Models in Strategy
- Logging: 'stream interrupted, falling back to <next-model>'

BETROFFEN: Alle Strategies (round-robin, weighted, fallback, single). Betrifft ALLE meta-models (heavy-model, scout-model, etc.) und direct providers.

PRIORITÄT: HIGH — betrifft ALLE Schiffe bei upstream-instabilität.

VERWANDT: Bug 'web autostart killt fremde Instanzen' (getrennt).

- 2026-10-15T11:36:04Z Enterprise: VERIFIZIERT ERLEDIGT (Enterprise): automatischer Fallback bei Stream-Abbruch ist implementiert — proxy.go:1438-1450: bei failed && attempt<attempts loggt 'stream interrupted (attempt d/d) — retrying with next model', record + Circuit-Breaker + Retry mit dem naechsten Modell der Strategy. (Verwandt: 7ce4c6f total-timeout-Fix.)
