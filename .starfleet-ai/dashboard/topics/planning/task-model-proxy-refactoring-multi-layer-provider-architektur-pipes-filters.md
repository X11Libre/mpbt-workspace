Title: "model-proxy Refactoring: Multi-Layer Provider-Architektur (Pipes & Filters)"
Category: planning
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-09T07:50:01Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: planning/task-model-proxy-refactoring-multi-layer-provider-architektur-pipes-filters

Design/Planung fuer die Neustrukturierung des starfleetctl model-proxy in eine mehrstufige Pipeline.

Ziel: generisches Stage-Interface (pipes & filters). Unterste Ebene = Upstream-Link-Adapter pro Provider-Type (NIM-Error-Erkennung, Zen-Header/UA-Synthese, Client-Locking), darueber Layer fuer Retries, Logging, Ship-State-Tracking, Strategies. Zentrales Objekt: Turn — das HTTP-Front sammelt den Request ins Turn, Pipeline-Stufen mutieren/erweitern es, zurueck kommt ein Reader-Objekt (Status/Streaming), final ggf. eine Reader-Pipeline aus mehreren Treibern.

Vollstaendiger Plan: Reports r-1791532131293803489@starfleet (design/model-proxy).

Bereits diskutierte Design-Entscheidungen:
- Schritt 1 (Request-Datensammlung): Turn traegt Transport-Meta (ctx, path, remoteAddr, requestID), Identitaet (shipID aus Authorization, sessionID aus X-Session-Id/x-opencode-session, x-opencode-* client/project/request), Body (RawBody als Wahrheit + geparste model/stream), und Pipeline-Zustand (strategy, provider, upstreamModel, effectiveLimit, attempt, metrics, errorClass).
- UA-Synthese: Zen-Gate prueft nur Format 'opencode/<version>' (live gemessen), nicht die exakte Version -> UA kann im Zen-Adapter synthetisiert werden statt durchgereicht; Session-ID dagegen MUSS durchgereicht werden (Prefix-Cache-Affinität).
- Modell-Rewrite (m["model"]=model) wird eigene Pipeline-Stufe statt Closure in forwardChat.

Naechster Schritt: weitere Design-Details + Implementierung (Phasen 1-7 im Report). LaForges Hoheit (starfleetctl-Source).
