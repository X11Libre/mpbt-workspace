---
slug: local/barcley-tempfile-incident-2026-09-09
title: "Barcley temp-file incident (2026-09-09)"
---

## Barcley temp-file incident (2026-09-09)

**Vollständiger Inhalt: Skill `android-kernel-rebase`** (`.claude/skills/android-kernel-rebase/SKILL.md`,
Abschnitte "Temp files — NEVER in the source tree", "How to resolve Kconfig conflicts",
"Known bad behavior — do not repeat").

Dieses Fragment ist nur noch ein Verweis-Stub — die Lessons aus dem Incident (Temp-File-Hygiene,
Konflikt-Auflösung via `--ours`/`--theirs`/`git show :2:`/`:3:`, keine hand-gerollten
AWK/sed-Skripte, `GIT_EDITOR=:` bei `git rebase --continue`) sind vollständig im
`android-kernel-rebase`-Skill dokumentiert (Fix-Commit 4e0025585d).

**Kurzregel:** Bei jeder Arbeit an einem Source-Tree: `_WORK_/<projekt>/tmp/` für Vergleichs-Dumps
nutzen, NIE Dateien im Quellbaum ablegen, vor Commit `git status --short` prüfen.