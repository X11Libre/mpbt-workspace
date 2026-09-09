Title: "Automatischer Model-Health-Check fuer proxied Provider"
Category: starfleet
Kind: "task"
Status: "in-progress"
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: "2026-09-08T11:28:34Z"
Doc-Ref: "—"

Neues starfleetctl-Subcommand (z.B. model-proxy check): prueft alle in models.yaml gelisteten Modelle der proxied Provider (nim-proxy, zen-proxy, nvidia-direct) auf grundsaetzliche Funktion. Default: Listing-Check gegen /v1/models des Providers; mit --probe: zusaetzlich minimaler 1-Token-Chat-Request. Retry bei transienten Fehlern (429/5xx/timeout), nur harte Fehler => failed. Ergebnis als Report; wiederkehrender Timer veroeffentlicht Fleet-Health-Bericht.

- 2026-09-08T11:29:09Z Enterprise: began work
