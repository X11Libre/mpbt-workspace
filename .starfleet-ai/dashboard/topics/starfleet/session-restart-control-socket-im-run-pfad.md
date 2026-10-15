Title: "session restart: Control-Socket im run-Pfad fehlt (nur web-gestartete Schiffe) + E2E offen"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-15T11:28:29Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/session-restart-control-socket-im-run-pfad

Rest-Befund aus bug-supervisor-autorestart-broken-scan-findings (dessen fixbarer Block in 9c899b4/475a2f8 erledigt ist).

## OFFEN
1. CONTROL-SOCKET IM RUN-PFAD FEHLT (Design-Lücke, im Code bestaetigt): spawnSession (internal/session/launch.go:1216) — der Pfad fuer stehende Schiffe (run) und autoscale — legt KEINEN Control-Socket an. Nur LaunchShip (launch.go:675-827) erstellt SocketPath/net.Listen. Folge: `session restart` / Web-Restart funktioniert nur fuer WEB-gestartete Schiffe, nicht fuer per `run`/autoscale gestartete.
2. VOLLER ship-restart-E2E ungetestet (spawnt echtes opencode — im Testbed zu flaky).
3. STATUS-RUNNING-Erkennung: unreaped child liest RUNNING (bewusst nicht geaendert — kein Client fragt STATUS ab; korrekter Fix braucht Lifecycle-Umbau).
4. launch.go:1432 TODO "trigger auto-restart with backoff".

## Vorschlag
Run-Pfad um einen Control-Socket erweitern (analog LaunchShip) bzw. den Supervisor-Lifecycle vereinheitlichen, damit restart fuer alle Startarten greift. Danach den E2E-Restart einmal real durchspielen.

## Refs
Quelle: starfleet/bug-supervisor-autorestart-broken-scan-findings (HIGH+MEDIUM/LOW dort gefixt). Skill starfleetctl-dev §6 (Branch+Testbed).
