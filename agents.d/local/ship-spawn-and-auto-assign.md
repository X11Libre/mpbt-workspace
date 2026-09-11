---
slug: local/ship-spawn-and-auto-assign
title: "Ship Spawn & Auto-Assign SOP"
order: 15
---

# Ship Spawn & Auto-Assign SOP

**Vollständiger Inhalt: Skill `workspace-auto-assign`** (`.claude/skills/workspace-auto-assign/SKILL.md`).

Dieses Fragment ist nur noch ein Verweis-Stub — der Inhalt wurde vollständig in den
`workspace-auto-assign`-Skill migriert (Auto-Assign-Verhalten, Spawn-Regeln, CLI/Web-
Beispiele, `--model`-Pflicht, Worker-Workflow, Flagschiff- und Spawn-Checklisten).

Kurzregeln (für den Notfall, ohne Skill-Load):

1. **Keine bare Args nach `session ship-run ... --`** — Tasks laufen über `task capture`/`task assign` + Comms.
2. **Auto-Assign (`__auto__`/`--assign`)** routet immer zum Flagschiff (Enterprise), das an einen freien
   Worker delegiert oder selbst übernimmt.
3. **Immer `--model` angeben** beim `session ship-run` (Default: Nemotron Ultra; Nano für leichte Tasks).
4. **Worker-Workflow:** Comms-Ack → Dashboard lesen → arbeiten → Ergebnis an Enterprise → `reports submit`.

Historie/Backend-Details: Fragment `local/starfleetctl-auto-assign-flagship` + Git-History.