Title: "Web-Daemon-Cron-Autostart: Minimal-PATH-Quirk"
Category: parked
Noted-By: ""
Since: "2026-08-03"

Folgendes in die lessons learned - local SOPs unter $WORKSPACE_ROOT/agents.d/local/... --------------------------------------------------------------------------------------


Der Web-Daemon wird vom Cron-Autostart (`starfleetctl web autostart`, jede
Minute) mit minimaler Umgebung gespawnt: `PATH=/usr/bin:/bin`, HOME=/home/nekrad.
Jeder Daemon-Neustart via Cron (nach Crash/Stop, oder wenn web.pid fehlt und
`web restart` den Port als belegt sieht) vererbt diese Umgebung an per Web
gestartete Schiffe.

Ursprünglicher Effekt (behoben): `exec opencode` im Ship-Start schlug fehl
("command not found") -> Schiff erschien ~1s auf dem Board, verschwand dann,
kein Prozess. Fix: starfleetctl 89733fa (resolveClientPath -> absoluter
opencode/claude-Pfad). Ship-Start ist damit PATH-unabhängig.

Offen / ggf. separat bewerten:
- `web restart` ersetzt den Daemon NICHT, wenn `.starfleet-ai/var/web.pid`
  fehlt/stale ist (Stop kann nichts killen, Autostart sieht Port belegt) —
  dann erst `kill <pid>`.
- `web start` läuft blockierend im Vordergrund (Daemonisierung nur über
  autostart/restart).
- Andere exec-Abhängigkeiten des Web-Daemons (ss, git, ...) laufen weiter mit
  Minimal-PATH — bisher unauffällig, aber ggf. auch hier absolute Pfade oder
  Daemon-Env aufbohren (bewusste Entscheidung nötig).
