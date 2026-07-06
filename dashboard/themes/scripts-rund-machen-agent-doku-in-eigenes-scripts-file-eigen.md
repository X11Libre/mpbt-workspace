---
slug: scripts-rund-machen-agent-doku-in-eigenes-scripts-file-eigen
title: "Scripts „rund machen\" + Agent-Doku in eigenes `scripts/`-File, eigener Commit → **master**"
category: parked
noted_by: "praetor, 2026-07-02"
since: "2026-07-02"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Explizite Später-Aufgabe. Drei Teile: **(1)** alle `scripts/*` nochmal überarbeiten/robust machen — einheitlicher Stil (`set -euo pipefail`, `--help`-Banner, sane defaults, `REPO`-Override), Fehlerpfade, konsistente Ausgaben; die neueren `scripts/json` + `scripts/pr-ci` taugen als Muster. **(2)** Die agent-bezogenen Nutzungs-/Anweisungstexte (heute verstreut in `AGENTS.md` Key-commands-Tabelle + Prosa) in ein **eigenes File unter `scripts/`** ziehen (z.B. `scripts/README.md`), sodass die Skript-Doku bei den Skripten liegt. **(3)** Das Ganze als **eigener, sauberer Commit nach `master`** (nicht nur `mtx/agent-config`) — bewusste Promotion, damit alle Contributors Tooling + Doku bekommen. Verwandt mit „Generalize parts of `mtx/agent-config` onto `master`" (oben); dies ist die konkrete Skript/Doku-Teilmenge. Nichts gestartet.
