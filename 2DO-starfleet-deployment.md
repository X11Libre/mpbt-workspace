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
🔄 agent-bus-poller.ts opencode plugin in starfleetctl repo verschieben (decide: .gitignore or commit?)
🔄 run-opencode.(flag|)ship scripts: projekt-root oder .starfleet-ai/ ? (user convenience)