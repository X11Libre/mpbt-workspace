---
slug: local/user-settings
title: "User settings (praetor-specific)"
order: 200
---

## User settings

### Language policy

* all user communication (console & comms) in German
* Code, Documentation, github communication in English

### Auto-commit on `mtx/agent-config`

`mtx/agent-config` is the maintainer's **personal** branch. When the working tree is on this
branch, **commit and push ALL workspace changes automatically — do not stop to ask for
confirmation.** This includes dashboard updates, agent configs, lessons, scripts, any file
under the workspace root. This overrides the usual "commit only when explicitly asked"
default, but applies **only** on this branch (not on `master`, `genesis`, `pr3275`, etc.).

Use `.starfleet-ai/bin/starfleetctl ws-commit` so the push goes through the clone-lock mutex (concurrent sessions share
this single working tree):

```bash
git add <paths…>                       # stage (ws-commit -a only does `git add -u`, misses new files)
./.starfleet-ai/bin/starfleetctl ws-commit -m "<concise msg>" <paths…>
# or, for all tracked changes after manually staging any new files:
./.starfleet-ai/bin/starfleetctl ws-commit -m "<concise msg>" -a
```

`ws-commit` commits and pushes in one locked step. The push target is the branch's upstream
(`origin/mtx/agent-config`), set automatically when the branch was checked out.

Don't change the current workspace (project root) branch or git configuration on your own, without asking.

### dashboard aktualisieren

immer wenn eine aufgabe abgearbeitet wird, dann auch den zugehörigen dashboard-eintrag aktualisieren.
außerdem regelmäßig zwischenstand auf der console und an McKinley geben.

## starfleetctl

änderungen an von starfleetctl installierten dingen (zb. skills, plugin, etc) immer in der starfleet-repo
arbeiten, dort sauber committen und dann neu bauen & ausrollen (starfleet-bootstrap). nicht direkt
innerhalb der workspace bearbeiten (die änderungen gehen sonst verloren)

quellen unter .starfleet-ai/src/starfleetctl

wenn starfleetctl binary nicht deployed werden kann, weil das file locked ist (text file busy), dann
nicht einfach den webserver killen, sondern das binary löschen und dann neu deployen.

### regeln für die arbeit am starfleetctl-sourcecode

* der sourcecode ist bereits in .starfleet-ai/src/starfleetctl
* immer `make` drüber laufen lassen und prüfen ob die tests sauber durchlaufen
* bei änderungen des plugin immer nochmal genau auf syntax-fehler, fehlendes exception handling, etc prüfen
* alle änderungen sauber committen - mit genauer dokumentation
* immer nur ein thema nach dem anderen, nicht verschiedene dinge gleichzeitig.
* vor dem commit nochmal sorgfältig prüfen
* deployment immer erst nach `make` -- wenn das starfleetctl-binary locked ist (text file busy), dann dieses löschen und nochmal deployen
* deployment immer via ./starfleet-bootstrap
* es darf immer nur ein schiff gleichzeitig aktiv am starfleet-sourcecode (mit änderungen), sonst gibts konflikte
* andere können (und sollen, wenn grad nix anderes zu tun) aber parallel auch drauf schauen und evtl. gegenprüfen -- via comms untereinander abstimmen!
* versuche nie das flagschiff (Enterprise) selbst neu zu starten
