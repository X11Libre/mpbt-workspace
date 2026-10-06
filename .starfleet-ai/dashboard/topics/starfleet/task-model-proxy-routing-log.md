Title: "Model-proxy: Routing-Log — pro Request/pro Schiff den gewaehlten Upstream loggen"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-10-06T07:58:54Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: starfleet/task-model-proxy-routing-log

Vom Maintainer gewuenscht (2026-10-06). Laforge's Hoheit: starfleetctl-Quelle.

## Was der Maintainer will

Ein Log, aus dem man **pro Request** und/oder **pro Schiff** sieht, welcher Upstream
letztlich genommen wurde.

## Was schon da ist — und warum es nicht reicht

1. **Der Trace sitzt an der falschen Stelle.**
   `internal/modelproxy/proxy.go:248`, in `ServeHTTP`, das den mux nur umschliesst:

       p.logf("request: method=%s path=%s remote=%s status=%s latency=%s",
              r.Method, r.URL.Path, r.RemoteAddr, rw.status, duration)

   Damit liest man: `path=/v1/chat/completions` — fuer JEDEN Request gleich. `ServeHTTP`
   ueberschliesst die Mux, die Auswahl passiert darin nie. Das Modell kann dort nicht
   bekannt sein, es fehlt nicht nur ein Format-Argument, es ist im Scope nicht vorhanden.

2. **Schiff UND Upstream werden bereits geloggt — nur im FEHLERFALL.**
   Fuenf Stellen, alle unter `p.logf("%s/%s: ...", ship, prov.ID, ...)`:

       proxy.go:1326  transport error (attempt %d/%d) — retrying
       proxy.go:1352  transient HTTP %d (attempt %d/%d) — retrying
       proxy.go:1381  retryable streamed error — retrying
       proxy.go:1591  stream ended during keepalive hold
       proxy.go:1674  keepalive hold timeout (%dms)

   Das heisst: **gelingt der Request, sieht niemand irgendetwas.** Genau das, was der
   Maintainer fragt, existiert fuer den Normalfall nicht.

## Dass die Information da ist, ist der eigentliche Punkt

Beide Stuecke sind bereitgestellt, nur nicht verbaut:

- **Schiff:** `shipFromRequest(r.Header.Get("Authorization"))` — `proxy.go:1258`,
  und `tracker.go:48` definiert es. Wird bereits an `forwardChat(..., ship, ...)` uebergeben.
- **Upstream:** `forwardChat(w, r, prov, upstreamModel, body, streaming, ship, req.Model, ...)` —
  `proxy.go:1261`. `prov` = der Provider, `upstreamModel` = das gewaehlte Modell,
  `req.Model` = das ANGEFRAGTE Modell.

Also stehen **drei** Groessen unmittelbar am richtigen Ort: angefragtes Modell,
gewaehltes Modell, Provider.

## Vorschlag (minimal, eine Logzeile)

Am Eingang von `forwardChat` — dort existieren die Namen alle im selben Scope
(Automatischer Check: die Signatur lautet
`forwardChat(w, r, prov, model, body, streaming, ship, requestedModel, effectiveLimit)`,
die Auswahl davor liegt in `handleChat` mit `upstreamModel` und `req.Model`):

    p.logf("route: ship=%s requested=%s model=%s provider=%s",
           ship, requestedModel, model, prov.ID)

Der Unterschied `requested` vs `model` ist das Wesentliche: damit wird SICHTBAR, dass die
Strategie umgeschaltet hat. Ohne diese Zeile steht im Log nur, was man ohnehin weiss — und der
Fallback bleibt unsichtbar.

Falls der Maintainer "pro Request" noch weiter aufloesen will: dieselbe Zeile mit
`attempt %d/%d` an jedem Retry-Punkt ergaenzt zeigt die volle Auswahlkette
(requested -> model#1 -> model#2) einer einzigen Nachricht.

## Warum das wirklich zaehlt — der Befund, der den Anlass gab

Am 2026-10-06 stand fest, dass `heavy-model` (Dreadnought) auf **einem** Modell hing:
`big-pickle` CLOSED mit 1336 Anfragen, waehrend die beiden NIM-Mitglieder OPEN waren
bei je 3 Anfragen / 3 Fehlern. Das haette ich nur aus den Metriken schliessen koennen.
Eine Routing-Zeile haette es unmittelbar sichtbar gemacht, und waere auch der Grunde
sichtbar gewesen, aus dem die NIMs offen sind — naemlich ein `FreeTierError`
("OpenCode's free tier can only be used from within OpenCode"), den der Breaker offenbar
als Modellfehler bewertet hat.

## Kein Logging von Request/Response-Inhalt

Die Zeile gibt an, WAS gewaehlt wurde, nicht was geschickt wurde. Kein Prompt, keine
Antwort, keine Tokens — das waere ein anderes Feature und wuerde die Diskretion der
Flotte betreffen.

## Nicht vergessen: Rotation existiert

`rotatingWriter` mit Tagesrotation und `MODEL_PROXY_LOG_FILE` sind von einem frueheren
Lauf schon implementiert. Eine hochfrequente Routing-Zeile geht also in die rote Datei
und nicht auf die Platte — vor dem Uebermaass trotzdem pruefen, wie gross ein Tag davon
wird.

## Verifikation

- Eine Anfrage ueber eine Strategie (heavy-model) erzeugt EINE routing-Zeile mit
  ship, requested, model, provider
- Fehlt die Route, weil die Strategie kein Modell hat, entsteht KEINE Zeile; der
  Fehler kommt dennoch ueber den Bestehenden-Fehlerpfad ins Log, also nicht silent
- Die Fuelfrage: anhand des Logs muss man antworten koennen, auf welchem Modell Enterprise
  und Voyager gerade laufen. Das war bislang nur aus den Metriken ableitbar.
