Title: "Automatischer Model-Health-Check fuer proxied Provider"
Category: active
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-08T11:28:34Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-automatischer-model-health-check-fuer-proxied-provider

Neues starfleetctl-Subcommand (z.B. model-proxy check): prueft alle in models.yaml gelisteten Modelle der proxied Provider (nim-proxy, zen-proxy, nvidia-direct) auf grundsaetzliche Funktion. Default: Listing-Check gegen /v1/models des Providers; mit --probe: zusaetzlich minimaler 1-Token-Chat-Request. Retry bei transienten Fehlern (429/5xx/timeout), nur harte Fehler => failed. Ergebnis als Report; wiederkehrender Timer veroeffentlicht Fleet-Health-Bericht.
