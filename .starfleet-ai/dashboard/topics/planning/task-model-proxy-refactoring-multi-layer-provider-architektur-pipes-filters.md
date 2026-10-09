Title: "model-proxy Refactoring: Multi-Layer Provider-Architektur (Pipes & Filters)"
Category: planning
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Enterprise"
Created: "2026-10-09T07:50:01Z"
Doc-Ref: "—"

Design/Planung fuer die Neustrukturierung des starfleetctl model-proxy in eine mehrstufige Pipeline.

Ziel: generisches Stage-Interface (pipes & filters). Unterste Ebene = Upstream-Link-Adapter pro Provider-Type (NIM-Error-Erkennung, Zen-Header/UA-Synthese, Client-Locking), darueber Layer fuer Retries, Logging, Ship-State-Tracking, Strategies. Zentrales Objekt: Turn — das HTTP-Front sammelt den Request ins Turn, Pipeline-Stufen mutieren/erweitern es, zurueck kommt ein Reader-Objekt (Status/Streaming), final ggf. eine Reader-Pipeline aus mehreren Treibern.

Vollstaendiger Plan: Reports r-1791532131293803489@starfleet (design/model-proxy).

Bereits diskutierte Design-Entscheidungen:
- Schritt 1 (Request-Datensammlung): Turn traegt Transport-Meta (ctx, path, remoteAddr, requestID), Identitaet (shipID aus Authorization, sessionID aus X-Session-Id/x-opencode-session, x-opencode-* client/project/request), Body (RawBody als Wahrheit + geparste model/stream), und Pipeline-Zustand (strategy, provider, upstreamModel, effectiveLimit, attempt, metrics, errorClass).
- UA-Synthese: Zen-Gate prueft nur Format 'opencode/<version>' (live gemessen), nicht die exakte Version -> UA kann im Zen-Adapter synthetisiert werden statt durchgereicht; Session-ID dagegen MUSS durchgereicht werden (Prefix-Cache-Affinität).
- Modell-Rewrite (m["model"]=model) wird eigene Pipeline-Stufe statt Closure in forwardChat.

Naechster Schritt: weitere Design-Details + Implementierung (Phasen 1-7 im Report). LaForges Hoheit (starfleetctl-Source).

- 2026-10-09T07:52:14Z Enterprise: Design-Korrektur: Turn ist REIN transport-agnostische Parameter-Struktur zum Starten eines Turns — kennt weder HTTP noch andere Transports. Start(cancel, turn) liefert ein EIGENES State/Connection-Objekt, aus dem gelesen wird (Status/Reader/Chunks/Meta). Transport-Meta (path/method/remoteAddr/Header/Request-ID/SSE-Framing) bleibt im jeweiligen Frontend. Identitaet (ShipID/SessionID) ist semantisch im Turn erlaubt (Frontend extrahiert aus seinem Transport). Laufzeit-State (provider/model/attempt/metrics) lebt im zurueckgegebenen State-Objekt, NICHT im Turn; Pipeline-Stufen mutieren das State-Objekt. Cancellation als generischer Handle, kein HTTP-context. Ziel: Pipeline fuer kuenftige Transports (gRPC/CLI/Batch) wiederverwendbar.

- 2026-10-09T09:03:35Z Enterprise: Design-Korrektur 2 (statt Mutation): Pipeline-Stufen mutieren den Turn NICHT in-place — sie reichen einen modifizierten (ggf. neuen) Turn nach UNTEN weiter (funktionaler Datenfluss turn -> stage -> turn' -> ... -> sink; Aufrufer-Turn bleibt unveraendert). Laufzeit-Entscheidungen der Stufen (gewaehltes Upstream-Modell, Provider, Remap) werden als Felder im durchgereichten Turn gefuehrt. ZURUECK kommt ein Reader-/State-Objekt (Lese-Handle: Status/Chunks/Meta); bei mehreren Treibern kann dieses Objekt selbst eine Pipeline aus Teil-Readern sein (Reader-Chaining). Also: runter = Turn-Transformationen; hoch/zurueck = Reader-Objekte. Meine frueheren Aussagen 'Stufen mutieren das State-Objekt' bzw. 'Turn bleibt unveraendert im State' sind damit praezisiert/ersetzt.

- 2026-10-09T09:04:00Z Enterprise: Namens-Entscheidung: Das zentrale Eingabe-Objekt heisst NICHT 'Turn', sondern 'LLMQuery'. Begruendung: es beschreibt die Anfrage (transport-agnostische Parameter zum Starten), nicht eine Turn-/Rundenstruktur. Ueberall im Design 'Turn' durch 'LLMQuery' ersetzen. Start(cancel, query LLMQuery) -> LLMQueryState/Reader; Pipeline-Stufen transformieren LLMQuery funktional nach unten und liefern Reader-Objekte zurueck.
