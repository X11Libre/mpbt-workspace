Title: "BUG comms: ack nicht idempotent (bereits gesene Nachricht = 'no such directive')"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-15T10:30:07Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: bug-comms-ack-nicht-idempotent

Bug-Analyse (Pre-Release, Enterprise, 2026-10-15) am master f267f92. master baut/vet/tet gruen; die drei geprueften Alt-Topics (plugin-version, poll-unseen, model-proxy-hang) sind im Code behoben. Drei NEUE Befunde:

## 1) HIGH-ish — `comms ack <id>` ist nicht idempotent (Kernprotokoll)
`ackMessage` (internal/comms/commands.go:524) prueft nur `msgs/<ship>/unseen/<id>.json` und den Legacy-Flat-Pfad. Da der Poller/Plugin jede gelieferte Nachricht per `seen_mark` (= DoAck, dispatch.go:494) sofort nach `seen/` verschiebt, schlaegt ein spaeteres manuelles `comms ack <id>` fehl mit `no such directive '<id>'` — **identisch** zur Fehlermeldung fuer eine nie existierende id.
Beleg: `comms ack m1287` / `comms ack m0027` (beide in Enterprise/seen/) -> rc=2 "no such directive"; `comms ack m999999` -> dieselbe Meldung.
Folge: Die SOP verlangt von jedem Schiff ein `ack` je Direktive; mit dem Plugin ist das systematisch nicht ausfuehrbar, und der Sender kann „schon verarbeitet" nicht von „unbekannt" unterscheiden.
FIX: in `ackMessage` zuerst pruefen, ob `b.mfileSeen(b.ShipID,id)` bereits existiert -> dann `return nil` (idempotenter No-op, ggf. andere Meldung „already seen"). Kein Verhalten sonst aendern.

## 2) LOW — Subcommand-`--help` wird ignoriert; bei `clear` gefaehrlich
`comms` behandelt `-h/--help` nur als `args[0]` (run.go:87). Ein `--help` NACH einem Subcommand wird verworfen. `comms clear --help` fuehrt real `DoClear()` aus und **loescht den eigenen Heartbeat** (beobachtet: „cleared heartbeat for 'Enterprise'"). Reparatur per `comms touch`. FIX: entweder generisch `--help` je Subcommand abfangen, oder `clear` (destruktiv) bei unerwarteten Arg-Listen mit usageErr abbrechen.

## 3) LOW — `seen/` wird nie gepruned
`DoPrune` (commands.go:884) raeumt stale Heartbeats + verbrauchte Direktiven, aber nicht `msgs/<ship>/seen/*.json`. Enterprise hat 3467 seen-Dateien (~700 KB), Tendenz steigend, ohne GC. FIX: beim Prune alte seen-Eintraege (aelter als N Tage) mit entfernen.

## Restliche Design-Luecke (kein Regression)
`internal/session/launch.go:1432` TODO „trigger auto-restart with backoff"; der run-Pfad (spawnSession/autoscale) legt keinen Control-Socket an -> `session restart` funktioniert nur fuer web-gestartete Schiffe (siehe starfleet/bug-supervisor-autorestart-broken-scan-findings).

## Einordnung Release
Kein Blocker unter den Befunden; #1 ist der relevanteste (Protokoll-UX). Empfehlung: #1 vor dem Release, #2/#3 direkt danach. Source-Owner: LaForge (per comms informiert).
