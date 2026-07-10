Plan für starfleet-deployment
==============================

* deployment unabhängig von MPBT
* teilt lediglich die philospohie, daß ein workspace-verzeichnis die gesamte arbeitsumgebung für ein projekt bzw. eine flotte abbildet
* das existierende ./bootstrap script hat nix mit autoconf zu tun 
* für diese aufgaben nicht in die existierenden mpbt-clones anderer teil-projekte schauen -- die interessieren uns grad nicht

Phase 1: initiales bringup (bei leerer repo) -- genesis
-------------------------------------------------------

* ein starfleetctl-Kommando installiert ein generisches starfleet-bootstrap script (evtl noch andere files) in der repo.
* dieses wird committed
* muß pro projekt nur einmalig getan werden (wiederholter aufruf spielt evtl. neue version ein - sollte aber nie nötig sein)
* das bootstrap-script sollte so schlank wie möglich sein

Phase 2: bootstrapping (zb. frisch geklonte repo oder spätere aktualisierung)
-----------------------------------------------------------------------------

* das bootstrap-script pullt starfleetctl (später ggf. pinned version), baut es und platziert alle nötigen files unter .starfleet-ai
* ruft auch starfleetctl auf, um agent-config-dinge wie zb. skills zu installieren / aktualsieren (claude & opencode)
* in phase 2 automatisch installierte files sollten .gitignore'd werden
* phase 2 kann jederzeit erneut gestartet werden -> uA. zum starfleet-update
* erzeugt auch die scripte um opencode-clients (entweder als flagschiff oder normales schiff) zu starten


2do
----

✅ agent-bus: schiffe sollten nicht ihre eigenen error-messages zurück bekommen (loop) -- FIXED: tell Enterprise statt broadcast
✅ agent-bus: keine error message emittieren, wenn der user abgebrochen hat (loop) -- FIXED: isUserAbort filter
✅ .bin/starfleetctl symlink entfernt -- wir haben jetzt alles unter .starfleet-ai/bin/
✅ .starfleet/ nach .starfleet-ai/ umbenannt
✅ agent-bus files (mbox, logs, ...) auch unterhalb von .starfleet-ai/agent-bus/
✅ agent-bus-poller.ts opencode plugin in starfleetctl repo verschieben -- DONE: installed via bootstrap from embedded fragments/opencode-plugins/
✅ run-opencode.(flag|)ship scripts: beide -- projekt-root convenience symlinks + embedded in starfleetctl fragments/opencode-scripts/, bootstrap installiert nach .starfleet-ai/bin/
✅ starfleet-bootstrap --> im starfleetctl eingebaut (self-install subcommand), genesis-init deployed bootstrap template (ohne cf/ layout)
✅ genesis-setup --> durch starfleetctl genesis-init ersetzt -- DONE: genesis-init existiert, erzeugt jetzt .starfleet-ai/ bootstrap statt cf/
✅ symlink .bin/starfleetctl ausmustern -> alles über .starfleet-ai/bin/ -- DONE: symlink entfernt, settings.json hooks/allowlist aktualisiert, starfleet-bootstrap/ws-commit/agent-run/run-claude*/run-opencode* aktualisiert
✅ automatisch installierte files sollten entsprechenden hinweis als comment tragen -- DONE: agent-bus-poller.ts run-opencode.* haben header comment "Auto-installed by starfleetctl bootstrap --fix"
✅ ./opencode.json noch nötig ? -- ja (minimal config, behalten)
✅ agent-bus-auto-id.sh noch nötig ? -- ja (aktiv genutzt für auto AGENT_ID)
⏭️ $AGENT_ID in $STARFLEET_SHIP_ID umbenennen ? -- später, würde alles brechen
✅ ./scripts/dashboard noch nötig ? -- ja (thin wrapper, noch referenziert)
✅ ./scripts/ship-names noch nötig ? -- ja (von agent-bus-auto-id.sh gecallt)
✅ ./scripts/ship-names.txt --> .starfleet-ai/etc/ -- DONE: moved to .starfleet-ai/etc/, symlink at scripts/ship-names.txt, shipnames Go code updated, bootstrap check updated, genesis template updated
✅ ./scripts/with-one-lock noch nötig ? -- ja (thin wrapper, von ws-commit gecallt)
✅ ./scripts/worktree noch nötig ? -- ja (aktiv genutzt)
✅ ./scripts/ws-commit noch nötig ? -- ja (thin wrapper, von scripts/dashboard gecallt)
⏭️ sind die scripts/pr-* scripte generisch oder Xlibre-spezifisch ? -- unentschieden/undringend
✅ ./scripts/json noch nötig ? -- ja (convenience, in settings.json allowlist)
✅ ./scripts/agent-permission-hook --> automatisch installieren (unter .claude) & .gitignore ? -- DONE: embedded in starfleetctl fragments/claude-hooks/, bootstrap installiert nach .claude/hooks/ + .gitignore Eintrag
⏭️ ./scripts/agent-bus-monitor-loop noch nötig ? -- ja, noch von Claude Monitor Tool benötigt
✅ starfleetctl --help implementieren -- DONE: helpText const + --help/-h flag, categorized subcommand overview
✅ command manual für starfleetctl --> in starfleet repo --> als .md und mit README verlinkt, sodaß man's schnell via github finden / anschauen kann -- DONE: README.md aktualisiert mit genesis/bootstrap deployment, genesis-init/self-install docs
* xlibre-spezfische dinge im starfleetctl --> sollten dort nicht sein
* wozu dient $AGENT_HANDLE ?
* Vorbereitung für multi-fleet: ein Flottille ist immer auf einem Host innerhalb eines Workspace (startrek-metapher: steht in einem System)
  später sollen verschiedene Flottillen (separate hosts oder workspaces) miteinander reden können 
* AGENT-CONTROL-PLANE.md --> outdated --> überhaupt noch nötig ?
* BIGFONT.md --> noch nötig ? evtl aufs dashboard ?
* CI-GOXTS-XEPHYR.md --> gibts einen besseren Platz ? xlibre-spezifische instructions oder dashboard ?
* DASHBOARD-RESTRUCTURE.md --> same
