Title: "release-blocker-Kandidat: supervisor/auto-restart kaputt + Scan-Befunde"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-10-14T12:40:09Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: starfleet/bug-supervisor-autorestart-broken-scan-findings

Pre-release-Bug-Scan (Stand master 2ea2503), verifizierte + unverifizierte Befunde. Triviale Bugs (#3/#4/#5) bereits gefixt in 2ea2503. Rest offen:

## VERIFIZIERT — HIGH (supervisor/auto-restart-Feature)
1. internal/session/launch.go:806-810 (+ return :893): LaunchShip registriert `defer { listener.Close(); os.Remove(controlSocketPath) }` und kehrt sofort zurueck -> Control-Socket sofort zerstoert + (in-process, web.go:1458) Accept-Busy-Loop (100% CPU/Log-Spam). `session restart`/Web-Restart schlaegt fehl.
2. internal/session/launch.go STOP-Handler (~:870): `close(shutdownCh)` ohne Once-Guard -> 2x STOP = Panic.
Architektur: cmd/ship-supervisor wird von NICHTS gestartet (toter Daemon; baut+deployt nach .starfleet-ai/bin/ship-supervisor). SocketPath 3x dupliziert (session/opencode/ship-supervisor). -> Feature entweder fertigstellen oder nicht als 'funktionierend' ausliefern.

## UNVERIFIZIERT (Subagent-Review, einzeln nachpruefen)
- medium internal/modelproxy/proxy.go:1646-1653: Scanner-Goroutine haengt beim Senden auf scanCh (Puffer 1) bei fruehem Return -> Goroutine-Leak pro abgebrochenem Stream.
- medium internal/session/launch.go:872-880: STATUS 'RUNNING' anhand childCmd.Process!=nil (bleibt nach Kind-Tod ohne Wait() true).
- medium internal/modelproxy/daemon.go:206-210 / web/autostart.go:469-481: Stop killt PID aus PID-File UNGEPRUEFT (stale/recycelter PID).
- low internal/web/autostart.go:453-466: killWebProcOnPort nur port-, nicht root-gescoped.
- low internal/session/launch.go:640-641: API-Mode setzt OPENCODE_CONFIG auf UDS-Pfad statt Config-JSON.
- low internal/session/launch.go:781: os.Setenv aus Goroutine (Env-Race).
- low cmd/ship-supervisor/main.go: Done() liefert nil (Busy-Loop), Race auf ship.Config.

Siehe auch: /proc/<pid>/exe vcs.revision fuer laufende Versionen; Skill starfleetctl-dev §6 (Branch+Testbed vor master).
