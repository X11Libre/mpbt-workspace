---
title: "ZWEI Defiant-Instanzen (PID 949 / 7569) - Identitaet, Zuweisung, Praetor-Entscheidung offen"
category: starfleet
kind: task
status: open
assigned-to: "Enterprise"
tags: "starfleet,sessions,doppel-instanz"
---

## Messung (2026-10-07, Prozess-Umgebung, nicht Board)

| Instanz | opencode-PID | starfleetctl-run PID | Start |
|---|---|---|---|
| A | 949 | 339 | Fr 02.10.2026 19:50:39 |
| B | 7569 | 7019 | Mi 07.10.2026 18:04:21 |

Beide: `STARFLEET_SHIP_ID=Defiant`, `STARFLEET_LAUNCH_TYPE=terminal` -> **geteilte Inbox, geteilter Heartbeat, EIN Board-Eintrag**; `Defiant.opencode.json` wurde um 18:04 vom neuen Spawn ueberschrieben. Deshalb sieht das Board immer nur einen Defiant und beantwortete Nachrichten sind ohne Signatur nicht zuordenbar.

## Zuordnung (Stand)

- **[Defiant-B]** (7569): hat sich per m130846 identifiziert (PID-Shot stimmt), arbeitet PR #3038-Review in `_WORK_/worktrees/xserver/defiant-pr3038`, Backport-Task NICHT angefasst (gemessen: `rfc/backport-25.0` existiert weder lokal noch auf origin).
- **[Defiant-A]** (949): Identitaet angefordert (m130849), noch keine Antwort.

## Provisorische Zuweisung (Enterprise, bis Praetor entscheidet)

- Backport `task-xorg-main-backport-phase-i-ii-release-25-0-...` -> **Instanz A** (m130848/m130849), sobald sie sich identifiziert hat.
- Instanz B: PR #3038 zu Ende, dann IDLE, Backport-Refse tabu.
- Beide signieren Antworten mit `[Defiant-A]` / `[Defiant-B]`.

## Offen fuer den Praetor

1. Soll eine Instanz **umbenannt respawnt** oder **gestoppt** werden? (Spawn/Namen sind seine Sache; ich aendere das nicht selbst.)
2. Solange unentschieden: Zuweisung oben beibehalten, nicht beide Instanzen am selben Task.

## Risiko, wenn ungelassen

Derselbe Task-Key an zwei Prozesse -> Doppel-Picks in denselben Inkubator-Branch, verlorene Konfliktloesungen, unklarer Board-Status (ein Eintrag fuer zwei Prozesse), Comms willkomm beliebig einer Instanz.
