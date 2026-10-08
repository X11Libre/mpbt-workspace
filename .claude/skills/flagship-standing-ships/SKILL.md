---
name: flagship-standing-ships
description: "Flagship (Enterprise) requirements for the standing ships in this workspace — ONLY the flagship needs these; other ships must not load or follow this skill. Use when respawning, monitoring, or delegating to Laforge/Barcley/Galaxy. Laforge owns the starfleetctl source and runs on the nim-primary meta-model. Not for doing starfleetctl work yourself — that is Laforge's domain."
---

# Standing Ships (Flagship-Anweisungen)

Diese Anweisungen gelten **nur für das Flagschiff (Enterprise) und nur für
dieses Workspace** (`mpbt-workspace`). Andere Schiffe müssen sie nicht kennen
oder beachten, und sollen diesen Skill **nicht** laden. Nicht in die
starfleetctl-Repo übernehmen.

## Ständige Schiffe

Folgende Schiffe müssen **stets vorhanden** sein (laufend, falls nötig
automatisch wieder hochgezogen):

- **Laforge** — einzuständig für **alle Arbeiten am starfleetctl-Source** (und nur
  dafür; keine xlibre/X11/os.h/desqview/Kernel-Tasks). Steht hier seit 2026-10-01;
  vorher war Scotty benannt, der nicht mehr Teil der Flotte ist.

  **Laforge gehört zur stehenden Flotte und ist IMMER da** (Entscheidung des
  Maintainers, 2026-10-02). Zwei Festlegungen daraus, die beim Neustart gelten:
  - **Immer `--launch-type background`.** Er gehört zur Flotte, nicht an eine
    Konsole. Ein Console-Launch heißt: da sitzt ein Mensch, und `session stop`
    reißt ihm die Sitzung weg. Heute liefen kurzzeitig **zwei** Laforge-Instanzen
    (eine termctl-gekapselte console, eine background) — Ursache war, dass er als
    Console-Schiff gestartet worden war und deshalb von `session stop` nicht
    erfasst wurde. Beim Neustart **vorher `ps -eo pid,cmd | grep "fleet ship
    Laforge"` prüfen** und bei mehr als einer Instanz erst aufräumen.
  - **Immer `--model nim-primary`.** Auch wenn die anderen Schiffe wegen
    NIM-Überlastung gerade auf `heavy-model` laufen: für Laforge ist
    `nim-primary` fest vorgeschrieben (unten begründet). Er wird **nicht** auf ein
    konkretes Nemotron-Modell gepinnt, auch nicht, wenn gerade eines frei ist.
- **Barcley** — zuständig für den **Volla-Kernel** (und nur dafür).
- **Galaxy** — für **verschiedene andere größere Aufgaben (on-demand)**.

**Ist-Zustand (2026-10-02, gemessen):** Laforge läuft wieder, **eine** Instanz,
`--launch-type background`, `--model nim-primary` (pids 541/551 nach dem
Neustart). Vorher stand er als **verwaistes Heartbeat** im Board, während kein
Prozess lebte — dieselbe Klasse wie der Barcley-Eintrag am Anfang dieser Sitzung:
Board-Eintrag und Prozesszustand widersprechen sich, und nur `ps` sagt, was lebt.

Achtung bei der Zustandsprüfung: **beide Prozesse eines termctl-gekapselten Schiffs
tragen den Ship-Namen in der Kommandozeile** — der Wrapper *und* sein opencode-Kind.
`grep -c` zählt damit **Zeilen, keine Instanzen**. Ein Wrapper mit einem Kind ist
*eine* Session. Instanzen zählt man anhand der Elternbeziehung.

Laforge läuft auf dem **Meta-Model `nim-primary`** (`opencode --model nim-primary`,
`server=meta-model`). Das reicht für den starfleetctl-Source ausdrücklich aus.

`nim-primary` ist eine **Strategie, kein gepinntes Modell** — sie wählt unter den
NIM-Modellen, was frei ist (`default_model` aktuell
`nvidia/nemotron-3-ultra-550b-a55b`). Genau die Indirektion ist gemeint: nicht auf
eine konkrete Modell-ID festlegen, damit Rate-Limits und Auslastung den
starfleetctl-Source nicht blockieren. Deshalb **kein** Hochziehen auf ein Nemotron
Modell, nur weil gerade eines frei ist — das verliert die Failover-Eigenschaft und
kostet Kapazität, die woanders fehlt.

Beim Neustart also `--model nim-primary` angeben, nicht
`nvidia/nemotron-3-ultra-550b-a55b`.

**Neustart bei Absturz:** siehe unten. Aktuell gibt es **keinen** automatischen
Wiederbelebungs-Mechanismus in starfleetctl (kein keepalive, kein respawn, kein
Health-Timer) — „immer da" ist eine organisatorische Auflage, keine technisch
erzwungene Eigenschaft. Ohne Timer oder Handeingriff bleibt ein abgestürztes
Schiff weg, bis jemand es bemerkt.

## Neustart bei Absturz / Stop

Wenn eines der drei Schiffe abstürzt oder gestoppt werden muss:

1. Automatisch wieder neu starten (`session ship-run --name <ship> --model <modell> --class worker --launch-type background`).
   Für **Laforge** ist `--model nim-primary` (das Meta-Model) das Vorgabemodell —
   nicht die darunterliegende Modell-ID.
2. Continuation-Direktive senden, damit es **an seiner Aufgabe weiterarbeitet**.
3. Vorher gestopptes zuständigkeitsfremdes Zuweisungen ggf. korrigieren (siehe
   "Task-Zuständigkeit" oben).

## Eigenständiges Arbeiten + Reports

- Die Schiffe müssen ihre zugewiesenen Tasks **sauber und eigenständig**
  abarbeiten (echte Arbeit, keine Platzhalter; Tools korrekt aufrufen; Tests
  laufen lassen; committen mit Doku).
- **Nach jedem abgearbeiteten Task einen starfleet-Report einstellen**
  (`starfleetctl reports submit`). Das Flagschiff stellt sicher, dass das
  passiert.
- Das Flagschiff **überwacht die Schiffe** (Board, Screens bei Auffälligkeiten)
  und tut das Nötige, damit sie durchgängig arbeiten können (Respawn,
  Continuation, Rate-Limit-Abwarten, Modellwechsel).

## Störungen dokumentieren (Reports)

Bei **jeder Störung** (Absturz, Stop, Loop, Rate-Limit, Blockade) und deren
**Behebung** wird ein starfleet-Report eingestellt (`starfleetctl reports
submit`), der **genau beschreibt**:

- **Was passiert ist** (Symptome: z.B. Repetitions-Loop, deutsches
  Prosa-Text als Bash-Kommando mit exit 127, 429 rate-limit, eingefrorener
  Screen, Kontext-Overflow).
- **Wie das Problem gelöst wurde** (z.B. session stop + respawn mit anderem
  Modell, Continuation-Direktive, Task-Neuzuweisung, auf Rate-Limit warten).
- **Welches warum** / Erkenntnisse.

Diese Reports dienen als **Lektionen für später** — wiederkehrende Muster,
funktionierende Modelle je Aufgabe, do's/don'ts beim Respawn. Wichtige
generalisierbare Erkenntnisse zusätzlich in die `sop.d/local/` knowledge
dump ablegen bzw. als SOP-Fragment promoten, wenn sie sich als stabil
erweisen.