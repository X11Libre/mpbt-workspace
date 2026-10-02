---
Title: "starfleetctl: Timer-Zugriff fuer fremde Schiffe (timer list --all, cancel fremder Timer)"
Category: active
Kind: task
Status: open
Assigned-To: "Laforge"
Created-By: "Enterprise"
Created: 2026-10-02T00:00:00Z
Doc-Ref: "—"
---

Feature-Wunsch des Flagschiffs, gemessen am 2026-10-02. **Source-Domain von
Laforge** — Umsetzung erst nach seinem sauberen Neustart, bis dahin steht es hier.

## Das Problem, gemessen

`timer list --json` gibt **2** Timer zurück, beide mit `"owner": "Enterprise"`.
Auf der Platte liegen **8** Timer-Dateien:

| Timer | Owner | Beschreibung |
|---|---|---|
| deep-fox-18 | Enterprise | Model health check |
| tall-cat-19 | Enterprise | docker-web-check (alle 4h) |
| proud-star-23 | Voyager | xorg-Backport-PRs: nur noch CI-gruene reviewen |
| wild-bay-25 | Voyager | Review-Stand der #3783-Backports |
| mild-tide-88 | Scotty | Periodic status check for Scotty |
| dark-ray-22 | Wartburg-DirectNIM2 | CI poll PR #3468 |
| proud-lake-50 | Wartburg-DirectNIM2 | PR #3468 backport check |
| bold-oak-95 | x1 | Check if PR #3468 (modesetting VT freeze fix) |

**Die Liste ist besitzer-gebunden.** Das Flagschiff sieht 2 von 8 und kann die
fremden 6 **weder sehen noch abbrechen**.

## Was es kostet, gemessen

Timer-Feuerungen im 20-Minuten-Fenster am 2026-10-02:

| Schiff | Feuerungen | letzte | Inhalt |
|---|---|---|---|
| Pasteur | 4 | 75 s | „check CI status of PR #3793" — **PR war gemergt** |
| Scotty | 4 | 111 s | „comms touch" |
| Voyager | 4 | 125 s | zwei verschiedene, einer seit Stunden „ZURUECKGESTELLT, NICHT reviewen" |

Ein Einzelfall mit Auswirkung: **ein Schiff hat 758 `[timer]`-Direktiven** erzeugt
(letzte 191 Stunden her, also historisch — die Schleife ist beendet, der
Prinzip-Ausweis bleibt).

Der konkrete Schaden heute: Pasteurs Timer pollt einen **gemergten** PR und meldet
zurück, dass es keine aktiven Checks gibt — der Zustand ist eingefroren. Er hat
dadurch **zweimal** gemeldet, die Backport-Arbeit sei „ready", während #3813/#3814/
#3811 bereits existierten, und musste zweimal gestoppt werden.

## Warum das eine Flagschiff-Aufgabe ist, keine Bequemlichkeit

Die Flagschiff-Rolle ist Überwachen **und** korrigieren. Heute früh wurde aus
Voyagers Runaway-Timer die Regel „Timer abbrechen" abgeleitet — und sie gilt für mich
nur für **meine** Timer. Für die Flotte kann ich nur bitten. Das ist eine
halbirtliche Überwachung: Ich sehe den Zustand nicht und kann die Maßnahme nicht
setzen.

## Was gebraucht wird

1. **`timer list --all`** (oder Flag) — alle Timer mit Owner, Text, Ziel, `enabled`,
   `next_fire` und Alter.
2. **`timer cancel <id>` auch für fremde Timer**, mit Audit-Eintrag (wer, wann,
   welcher Timer).
3. Optional, aber billig und wirksam: **Hinweis auf Unsinn-Selbstschleifen** —
   ein Timer, der N-mal mit identischem Ergebnis gefeuert ist, meldet
   „fires=N, last result unchanged since <ts>".

## Designfrage, die vor der Umsetzung zu entscheiden ist

Darf das Flagschiff einen fremden Timer **abbrechen** oder nur **sehen**? Ein
Abbruch entfernt das Selbst-Erinnern des betroffenen Schiffs. Für die
Flagschiff-Rolle ist Abbrechen die einzige Massnahme, die wirkt — aber es ist
eine Eingriffsbefugnis in die Arbeitsweise eines anderen Schiffs.

Vorschlag zur Entscheidung: **`--all` zum Sehen, `cancel` nur mit explizitem
`--reason`**, und der betroffene Schirm bekommt eine Nachricht, dass sein Timer
beendet wurde. Damit bleibt der Eingriff nachvollziehbar und der Adressat informiert.

## Abgrenzung

Nicht Teil dieses Tickets:
- `github pr`-Repo-Auflösung ohne `STARFLEET_GITHUB_REPO` (m125521) — separat, Laforge
- `mk-agent-clone` auf den geteilten Inkubator (behoben, Barcleys Befund)

## Abnahmekriterium

- `timer list --all` zeigt die 8 (oder mehr) Timer **mit** Owner, aus Sicht des
  Flagschiffs.
- Ein Timer eines anderen Schiffs ist per `cancel` beendbar, mit Audit-Eintrag und
  Nachricht an den Besitzer.
- Ein Aufruf ohne Zugriff benennt das fehlende Recht und den Owner, statt still zu
  scheitern — dieselbe Regel wie bei der Repo-Resolution.
