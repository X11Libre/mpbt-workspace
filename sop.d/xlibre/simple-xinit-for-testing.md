---
slug: xlibre/simple-xinit-for-testing
title: "Use simple-xinit when launching a test X server + client"
order: 95
---

## Use simple-xinit when launching a test X server + client

**Vollständiger Inhalt: Skill `xserver-testing`** (`.claude/skills/xserver-testing/SKILL.md`).

Dieses Fragment ist nur noch ein Verweis-Stub — der Inhalt wurde vollständig in den
`xserver-testing`-Skill migriert (NEVER-do-this, Syntax mit `--`-Separator, Schritt-für-
Schritt, Verify, Cleanup, Common-Mistakes-Tabelle, Environment-Variables-Regel).

Kurzregeln (für den Notfall, ohne Skill-Load):

1. **NIE `Xvfb :N &` dann Client** — immer `simple-xinit <client> -- <server> ...` als Paar starten.
2. Der `--`-Separator zwischen Client und Server ist **zwingend**.
3. Absolute Pfade nutzen; Server-Binary aus `_WORK_/<release>/target/bin/` (nicht das System-Binary).
4. Client braucht Env-Vars (DISPLAY etc.)? → Client in Script wrappen (`exec`).
5. Hintergrund-Betrieb: `simple-xinit ... &` + PID merken, dann `kill $SIMPLE_PID` zum Aufräumen.

Beispiel:
```bash
SIMPLE_XINIT=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/simple-xinit
XVFB=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/Xvfb
$SIMPLE_XINIT xterm -- $XVFB :99 -screen 0 1024x768x24
```