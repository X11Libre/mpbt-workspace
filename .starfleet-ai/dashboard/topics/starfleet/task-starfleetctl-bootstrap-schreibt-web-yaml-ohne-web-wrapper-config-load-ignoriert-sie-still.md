Title: "starfleetctl: bootstrap schreibt web.yaml ohne 'web:'-Wrapper (config.Load ignoriert sie still)"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-10T12:04:00Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/task-starfleetctl-bootstrap-schreibt-web-yaml-ohne-web-wrapper-config-load-ignoriert-sie-still

Bug (gefunden beim Testbed-Aufbau 2026-10-10). 'bootstrap --fix' legt .starfleet-ai/conf/web.yaml FLACH an (Top-Level: listen_addr:, autostart_enabled:, ...). config.Load (internal/config/config.go) liest web.yaml aber ueber den Top-Level-Key 'web' (raw map, node := raw["web"]). Ein flaches File hat diesen Key nicht -> die Datei wird KOMPLETT ignoriert, cfg.Web bleibt Default (0.0.0.0:8080). Kein Fehler, keine Warnung.

FOLGE: Wer in einer frischen Workspace bootstrap --fix laufen laesst und dann listen_addr in web.yaml aendert, bewirkt NICHTS (laeuft weiter auf Default 8080). Unsere Live-web.yaml hat den 'web:'-Wrapper (handgepflegt), die bootstrap-Vorlage nicht -> inkonsistent.

FIX: entweder fixWebConfig() soll den 'web:'-Wrapper schreiben (wie die Live-Conf), oder config.Load soll das flache Format akzeptieren. Pfad: internal/bootstrap/checks.go (fixWebConfig, ~Z.1288/1300) bzw. internal/config/config.go Load().

Bestaetigt im Test: Testbed-conf flach -> 'web autostart' meldete 'web server running' (Port fiel auf Default 8080 = Live) statt :18080. Nach Wrapper im Testbed: korrekt :18080.
