Title: "Web-Daemon-Cron-Autostart: Minimal-PATH-Quirk"
Category: done
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

## Resolution (2026-08-03, starfleetctl 022cd9b + 1216187)
Open items addressed:
- Daemon PATH: Daemonize() expands the child PATH (caller PATH + /usr/local/sbin,
  /usr/sbin, /usr/local/bin, ~/.local/bin, ~/bin) — no longer depends on the
  minimal cron env; covers ss/git/opencode and any other exec'd helper.
- web restart stale-pid: Restart() now kills the running daemon via a pure
  /proc cmdline scan (web start + --addr port) when Stop couldn't kill (missing/
  stale web.pid), then Autostart starts a fresh daemon and rewrites web.pid.
  The previous ss-based detection was a no-op (ss shows only comm "starfleetctl",
  never the "web" argv) and has been removed entirely — no ss dependency left.
- web start blocking foreground: by design (daemonize only via autostart/restart);
  documented in agents.d/local.
Verified end-to-end: corrupt web.pid → restart → fresh pid + HTTP 200; normal
restart likewise. Lesson appended to agents.d/local/local-knowledge-dump.md.
