Title: "xlibre: Backport PR #3557 (darwin thread priorities) auf die Release-Zweige"
Category: xlibre
Kind: task
Status: "in-progress"
Created-By: "Enterprise"
Created: "2026-09-30T09:48:10Z"
Assigned-To: "Enterprise"
Doc-Ref: "https://github.com/X11Libre/xserver/pull/3557"
Slug: xlibre/task-xlibre-backport-pr-3557-darwin-thread-priorities-to-release-25-1

Backport von PR #3557 ("darwin: Set thread priorities to user interactive or user
initiated as appropriate", master-Commit 718e1aa81b) auf alle Release-Zweige.
Betroffene Dateien: hw/xquartz/X11Application.m, hw/xquartz/darwinEvents.c,
hw/xquartz/quartzStartup.c, os/inputthread.c.

Backport-Matrix (PR-Body von #3557, Tabelle "Backport dashboard"):

| Target branch | Backport PR | Status |
|---------------|-------------|--------|
| release/25.2  | #3573 | OPEN — 0 CI-Checks gemeldet, nie gelaufen |
| release/25.1  | #3767 | MERGED 2026-09-30 |
| release/25.0  | #3605 | MERGED 2026-08-24 |

## Korrektur einer früheren Fehlaussage (Enterprise, 2026-09-30)

Ich hatte gemeldet, 25.1 habe keinen Backport. **Das war falsch.** Ich hatte nur
`git log --grep` benutzt; der Commit-Titel des Backports traegt nicht die PR-Nummer,
sondern den Original-Subject — `--grep="3557"` und `--grep="darwin: Set thread
priorities"` liefern beide nichts, obwohl der Commit da ist. Der Nachweis kam erst
ueber `gh pr list --search` (PR-Nummern im Body der Backport-PRs).

Merksatz fuer den naechsten Lauf: **Anwesenheit eines Backports ueber die PR-Liste
feststellen, nicht ueber `git log --grep` auf die PR-Nummer.** Auf 25.1 lag
d44551d41d mit identischem Autor/Datum/Subject wie master, was ich als "nur 25.0/25.1
haben ihn" gelesen hatte — richtig, aber ich habe daraus die falsche Schlussfolgerung
fuer den PR-Status gezogen.

## Offen: release/25.2

#3573 ist offen und hat **nie einen einzigen CI-Check gemeldet** (0 checks, nicht
"pending"). Das ist der Grund, warum es im Dashboard nicht auffiel. Inhaltlich fehlt
der Thread-Priority-Commit in 25.2 weiterhin — der dortige Baum traegt nur den
unabhaengigen OOM-Fix `b9a6330267` aus dem alloc-fail/UAF-Sweep, der denselben
Root-Cause angeht aber nicht diesen Commit ersetzt.

Naechster Schritt: CI fuer #3573 anstossen (`gh run list --branch
pr/release/25.2-darwin-set-thread-priorities-...`) oder den PR manuell mergen.
**Release-Merges bleiben manuell, durch den Praetor** — ich merge nichts.
