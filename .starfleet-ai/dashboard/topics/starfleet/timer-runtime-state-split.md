---
title: "Refactor (später): Timer-Runtime-State aus den git-getrackten conf/timers splitten"
category: parked
kind: "task"
status: "open"
assigned-to: "—"
tags: "starfleetctl,timers,git-hygiene,post-release"
---

## Problem (Praetor, Console 2026-10-15; von Defiant gemessen)

`.starfleet-ai/conf/timers/*.json` ist **git-getrackt** (Definitionen zu Recht
— die sollen archiviert bleiben). Der Timer-Worker schreibt aber
**Runtime-State in dieselbe Datei**: nach jedem Lauf mutiert `next_fire`
(gemessen via `git diff`: purge-monthly + wild-sky-38 mit `next_fire`-Bump,
laufender Working-Tree). Folge: dauerhaft uncommitted changes im
mpbt-repo, Waescheline aus reinem Timestamp-Rauschen.

Nebenbefund beim Messen: `sweep-stale.json` lag zeitweise **leer** im Diff
(`e69de29`) — der read-modify-write in die Definationsdatei ist offensichtlich
nicht atomar. Ein Absturz mitten im Write zerstoert die Definition.

**Zieltrennung:** Definition (id, description, owner, target, type, text,
schedule, persistent, enabled, created_at) = git-archiviert.
Runtime-State (next_fire, ggf. last_run) = NICHT git-archiviert.

## Optionen (Entscheidung offen)

1. **State-Split (naheliegend):** Runtime-State nach
   `.starfleet-ai/var/timer-state/<id>.json` (var/ ist bereits
   komplett ignoriert — `.starfleet-ai/.gitignore:10 /var/timers/`).
   conf/timers/ waere danach write-free ausser bei Timer-CRUD.
2. **File-Timestamps (Praetor-Idee):** `next_fire` als mtime der
   Timer-Datei (`touch -d @<epoch>`). Vorteil: null State-Dateien.
   Caveats vorab zu klaeren: relatime/noatime betreffen atime (unbrauchbar),
   mtime ist ok, aber (a) jeder Write an der Definationsdatei wuerde den
   Zeitpunkt zerstoeren — wuerde also den Split ohnehin voraussetzen,
   (b) Auflösung/Portabilitaet, (c) Debugging sieht man den Wert nicht ohne
   `stat`. Bewertung: elegant, aber m.E. (Defiant) State-Split robuster —
   hier entscheidet Praetor/Source-Owner.
3. **Ableitung ohne Persistenz:** `next_fire` aus `schedule` + `now`
   berechnen (cron: naechster Slot; interval: braucht `last_run` oder
   akzeptiert Drift beim Reload). Spart State-Datei, kostet Korrektheit
   bei Reload-Mitten-in-interval. Nur vollstaendig ohne State bei cron.

## Umsetzungshinweis

- Timer-Code: `internal/timer/` (worker/types/store — beim Umsetzen genau
  ansehen, welches Modul schreibt).
- Schreibpfad gleich mit atomarisieren (temp+rename), weil der
  sweep-stale-Leer-Write-Beleg zeigt, dass Definationsdateien sonst
  kollateraler Schaden sein koennen.
- Compat: bestehende next_fire in conf-Dateien migrieren (beim ersten
  Start State anlegen, next_fire aus Definations-Datei uebernehmen,
  danach Definations-Datei nur noch CRUD-write).

## Timing / Owner

- **NACH dem Release** (Praetor-Vormerkung, wie
  starfleet/refactor-generic-rfc822-util).
- Owner: starfleetctl-Source (LaForge-Hoheit; derzeit Enterprise-Claim).
- Offen: Praetor entscheidet Option 1/2/3.
