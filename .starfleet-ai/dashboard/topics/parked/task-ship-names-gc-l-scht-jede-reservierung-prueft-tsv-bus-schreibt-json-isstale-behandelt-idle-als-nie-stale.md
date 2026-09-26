Title: "ship-names: gc löscht jede Reservierung (prueft .tsv, Bus schreibt .json) + isStale behandelt idle als nie-stale"
Category: parked
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-26T11:48:45Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/task-ship-names-gc-l-scht-jede-reservierung-prueft-tsv-bus-schreibt-json-isstale-behandelt-idle-als-nie-stale

Befund aus der Diagnose "Galaxy laeuft nicht mehr, aber Web-Frontend denkt der Name ist belegt" (m123960).

URSACHE 1 - stale reservation, nicht der Web-Frontend
var/comms/ships/Galaxy existiert als Reservierungsdatei:
  19876:1790269862:/dev/null   PID 19876 ist DEAD, Alter 42.9h
Dazu var/ships/Galaxy.log, Galaxy.opencode.json, Galaxy.pipe. Kein Prozess, keine Status-Datei, kein Board-Eintrag. Alles was die Belegung ueber die Reservierungsdatei prueft, meldet Galaxy korrekt-rechtmaessig als belegt.

Das Web-Frontend selbst ist unschuldig: die Schiffs-Dropdowns in index.html werden ausschliesslich aus taskState.board gebaut (internal/web/index.html:1602, :1677, :1812). Galaxy steht nicht im Board, taucht dort also nicht auf. Galaxy erscheint nur in der Session-Liste (api/sessions, 3 opencode-Sessions mit running:false) - das ist Verlauf, keine Namensbelegung.

BUG A (schwer, destruktiv) - ship-names gc ist kaputt und wuerde alles loeschen
internal/shipnames/commands.go:374 (DoGC) prueft auf var/comms/status/<name>.tsv.
Der comms-Bus schreibt aber var/comms/status/<name>.json (internal/comms/comms.go:166, commands.go:180 "single source of truth").
Es gibt keinen Writer fuer .tsv - in var/comms/status/ liegen ausschliesslich .json (Barcley, Enterprise, Interpid, McKinley, Voyager). .tsv existiert im Code nur noch in comms (msgs, Legacy) und prclaim.

Folge: DoGC haelt JEDE Reservierung fuer stale und loescht jede Datei in var/comms/ships - also auch die lebenden Reservierungen von Interpid (PID 27701) und Voyager (PID 25648). Ein gc-Lauf wuerde aktive Schiffe den Namen entreissen.
Zusaetzlich prueft DoGC weder PID-Lebendigkeit noch Epoch-Alter, nur die Existenz der (nie vorhandenen) Statusdatei.

BUG B - isStale() behandelt idle als nie-stale
internal/shipnames/commands.go:223: if state == "idle" { return false } - ein Schiff im Status idle gilt damit unendlich lange als frisch, unabhaengig vom Alter. Barcley ist seit 167.6h tot, Status idle, Reservierung PID 11941 DEAD - wird nie als stale erkannt.

NEBENBEFUND - Enterprise hat gar keine Reservierung
var/comms/ships/ enthaelt keine Datei fuer Enterprise, obwohl Enterprise laeuft (PID 24843, session run --flagship). Der Flagship-Namensschutz greift waehrend der Laufzeit nicht, der Name waere theoretisch vergebbar.

AKTUELLER ZUSTAND DER RESERVIERUNGEN (Diagnosezeitpunkt)
  Barcley    11941 DEAD   167.6h
  Discovery  32751 DEAD    21.4h
  Galaxy     19876 DEAD    42.9h
  Pasteur    22591 DEAD    16.2h
  Scotty      4477 DEAD   210.9h
  TestMeta    7790 DEAD   223.1h
  Interpid   27701 alive    2.9h
  Peking     28444 alive  235.3h   <- PID-Reuse-Verdacht, Reservierung ist 235h alt
  Voyager    25648 alive    3.4h

VORSCHLAG
- DoGC auf PID-Lebendigkeit plus Epoch-Alter umstellen (isPIDDead existiert bereits in commands.go:67) und StatusDir-Endung auf .json korrigieren.
- isStale(): idle nicht mehr pauschal als frisch behandeln, sondern auch beim idle-Zustand das Epoch-Alter gegen BusTTL pruefen.
- Flagship waehrend der Laufzeit reservieren.
- Kurzfristig: stale Reservierungen und var/ships-Reste per rm entfernen, NICHT per ship-names gc.

NICHT AUSGEFUEHRT: Es wurde nichts entfernt und gc wurde nicht aufgerufen. Entfernen ist eine mutierende Aktion an der Fleet, das braucht eine Freigabe.
