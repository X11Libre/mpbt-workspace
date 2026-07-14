---
title: "Starfleet: reuse ship name if previous session was on local terminal and had been killed"
category: active
status: "done"
assigned-to: "Agamemnon"
created-by: ""
created: ""
doc_ref: ""
tags: "starfleet"
---

Wenn ein schiff (normales, nicht das flagschiff) im terminal lief und beendet wurde,
und dann im gleichen terminal wieder neu gestartet wurde (typischer restart-cycle,
zb. um plugin neu laden, etc), dann soll der gleiche schiffname wieder verwendet werden.

Abgleich zb. über TTY/PTY:

wenn also ein schiffsname auf das gleiche tty/pty registriert wurde, und dann aber die
zugehörige PID nicht mehr existiert, dann kann der vorige agent offenbar nicht mehr
mehr laufen, und wir können uns diese registrierung greifen und den schiffsnamen weiter benutzen.
