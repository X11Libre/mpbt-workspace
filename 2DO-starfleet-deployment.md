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

* genesis-setup --> durch starfleetctl genesis-init ersetzt --> nicht mehr in den individuellen workspace-repos nötig
*./opencode.json noch nötig ? --> würde das entfernen starfleet brechen ? wenn ja, warum ?
* agent-bus-auto-id.sh ausmustern, sofern nicht zwingend nötig
* ./scripts/dashboard ausmustern, sofern nicht zwingend nötig
* ./scripts/ship-names ausmustern, sofern nicht zwingend nötig
✅ ./scripts/ship-names.txt --> .starfleet-ai/etc/ -- DONE: moved to .starfleet-ai/etc/, symlink at scripts/ship-names.txt, shipnames Go code updated, bootstrap check updated, genesis template updated
✅ ./scripts/with-one-lock noch nötig ? -- ja (thin wrapper, von ws-commit gecallt)
✅ ./scripts/worktree noch nötig ? -- ja (aktiv genutzt)
✅ ./scripts/ws-commit noch nötig ? -- ja (thin wrapper, von scripts/dashboard gecallt)
✅ sind die scripts/pr-* scripte generisch oder Xlibre-spezifisch ? -- AUDIT DONE: pr-amend-push/pr-claim generisch, rest per $REPO konfigurierbar mit X11Libre/xserver default, pr-checkout hat XLibre-Pfadannahmen
✅ ./scripts/json noch nötig ? -- ja (convenience, in settings.json allowlist)
*️ ./scripts/agent-bus-monitor-loop noch nötig ? -- JA, Go monitor-loop hat bekannten Monitor-Tool-Bug (README Known limitations). Kann später als embedded fragment in starfleetctl (claude-hooks/) + auto-install via bootstrap, aber bash-Version bleibt bis Go-Bug gefixt ist.
✅ command manual für starfleetctl --> in starfleet repo --> als .md und mit README verlinkt, sodaß man's schnell via github finden / anschauen kann -- DONE: README.md aktualisiert mit genesis/bootstrap deployment, genesis-init/self-install docs
✅ xlibre-spezfische dinge im starfleetctl --> DONE: DefaultRepo entfernt, Repo() eingeführt mit STARFLEET_GITHUB_REPO env, Kommentare gesäubert. Verbleibend: session/pkg *xserver-* release prefix noch XLibre-spezifisch (nicht kritisch)
✅ wozu dient $AGENT_HANDLE ? -- tmux session name (flagship/worker01), gesetzt in session/launch.go, von agentbus als status-label verwendet
* Vorbereitung für multi-fleet: ein Flottille ist immer auf einem Host innerhalb eines Workspace (startrek-metapher: steht in einem System)
  später sollen verschiedene Flottillen (separate hosts oder workspaces) miteinander reden können 
* AGENT-CONTROL-PLANE.md --> outdated? --> NEIN, aktives Architektur-Dokument. Keep.
* BIGFONT.md --> noch nötig ? --> JA, Referenz für BigFont extension. Keep (evtl später nach docs/).
* CI-GOXTS-XEPHYR.md --> gibts einen besseren Platz ? --> Warum verschieben? Ist operational knowledge, genau richtig im root. Keep.
* DASHBOARD-RESTRUCTURE.md --> aktueller Design-Entwurf (pending review vom 2026-07-06). Keep.
✅ scripts/ship-names.txt symlink --> JA, agent-bus-auto-id.sh referenziert es noch. Keep.
✅ ./starfleet-bootstrap --> auto-install notice ergänzt (auch im genesis-template)
