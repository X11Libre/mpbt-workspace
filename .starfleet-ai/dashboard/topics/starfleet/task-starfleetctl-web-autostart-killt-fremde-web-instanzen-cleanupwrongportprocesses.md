Title: "starfleetctl: web autostart killt fremde web-Instanzen (cleanupWrongPortProcesses)"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "LaForge"
Created-By: "Enterprise"
Created: "2026-10-10T12:03:46Z"
Doc-Ref: "—"

Bug (gefunden beim Testbed-Aufbau 2026-10-10). internal/web/autostart.go cleanupWrongPortProcesses(expectedAddr): iteriert webStartProcs() (/proc-scan aller 'starfleetctl web start') und killt JEDEN Prozess, dessen --addr-Port != expectedPort.

FOLGE: Betreibt man eine zweite Web-Instanz (z.B. Testbed auf :18080), killt deren 'web autostart' den Live-Web auf :8080 (und umgekehrt). Damit ist 'web autostart' fuer Multi-Instance unbrauchbar; der robuste Go-Daemonizer (cmd.Start+Release, ueberlebt Session-Restarts) steht fuer eine 2. Instanz nicht zur Verfuegung.

FIX-VORSCHLAG: cleanup nur auf Instanzen DESSELBEN Roots/Conf scopen (z.B. cmdline/root bzw. Binary-Pfad abgleichen), nicht global auf alle 'web start'. Kontrolle: der Go-Daemonizer in web/autostart.go Daemonize() arbeitet korrekt, nur der Vorab-Cleanup ist zu breit.

REPRO: live :8080 laeuft; Testbed-web.yaml listen_addr 127.0.0.1:18080; 'web autostart' im Testbed -> Live-Web wuerde gekillt.

Workaround bis Fix: Testbed startet 'web start' direkt (setsid), NICHT 'web autostart'. Ich habe den Live-Web waehrend meiner Tests NICHT gekillt (Zufall: falscher Port in kaputter Conf).

- 2026-10-15T11:28:03Z Enterprise: VERIFIZIERT ERLEDIGT (Enterprise): cleanupWrongPortProcesses(expectedAddr, root) ist root-scoped — procWorkspaceRoot(cwd)+samePath(procRoot,rootAbs) (autostart.go:332-333/477) und util.IsStarfleetctlPID (:496). 2. Instanz (Testbed :18080) killt Live-Web :8080 nicht mehr. Fixes 62ebdb8/4d7903a.
