Title: "Model-Proxy Fallback/Streaming-Fixes: unabhaengiges Review + adversariale Verifikation"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-16T08:22:43Z"
Assigned-To: "Rosetta"
Doc-Ref: "—"
Slug: starfleet/task-review-model-proxy-fallback-streaming-commits

Unabhaengiges Zweit-Review der vier frisch deployed model-proxy Commits auf master (head 3c53ddb). Owner des Sources bleibt LaForge — NUR LESEN/BAUEN/TESTEN, keine Writes/Commits am starfleetctl-Source; Findings als Bericht (comms an Enterprise + LaForge) plus optional Patch-Vorschlag loku00e1l.

Zu pruefen (Risikoliste, gezielt):
1) feat: 5xx-Fallback — attempts := MaxRetries+1, Lift auf min. 2 fuer Strategy-Routen: greift der Lift auch fuer DIREKTE (Nicht-Strategie) Routen korrekt NICHT? Test TestChatNonTransientNotRetried (echtes 400 genau 1 Call) belegt.
2) streaming fallback: Bedingung (attempt < attempts || (attempt == attempts && attempts == 1)); kein doppelter [DONE]; strukturiertes error-Event (stream_interrupted) + [DONE] bei Abbruch; Keepalive-Interaktion.
3) http.Client.Timeout: Streams MUESSEN einen Client OHNE Client.Timeout nutzen (Client.Timeout deckt die ganze Transaktion inkl. Body-Read) — pruefen: streamClient/nonStreamClient, Transport-Timeouts statt Client.Timeout.
4) 3c53ddb (400 DEGRADED function): upstreamFaultText-Matching (zu breit? zu eng?), Budget-Lift gebunden (attempts<2), faultTag-Format, SSE-Fault nur VOR erstem Content, Probe-Klassifikation degraded vs failed.
5) Circuit-Breaker-Interaktion: force-open beim Fallback, Cooldown, HalfOpen-Metriken-Reset, Lock-Reihenfolge cb.mu vor metrics.mu (Deadlock?).
6) doc/config.md vs Code: max_retries-Semantik (Default 0 = ein Versuch; negativ = 3) stimmt mit config.go ueberein?

Akzeptanz: (a) build+vet+go test -count=1 ./... gruen nachvollzogen; (b) mind. ein reproduzierbares Gegenbeispiel ODER explizite Bestaetigung je Risikopunkt — Vermutungen klar als 'ungemessen' markiert; (c) Bericht via comms an Enterprise + LaForge.

Anschluss (nur nach Freigabe/Absprache, nicht sofort): Triage der drei offenen starfleetctl-Comms-Bugs (bug-comms-ackmessage-race, bug-comms-ackmessage-missing-unseen-cleanup, bug-comms-broadcast-partial-success) — Root-Cause + Repro, Patch lokal.
