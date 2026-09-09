---
slug: local/enterprise-deletes-topics-lesson
title: "Never delete dashboard topics / editor lock files"
order: 20
---

# Enterprise deleted a manually-created dashboard topic during startup

Bug: `starfleet/bug.enterprise-deletes-topics` (2026-07-30). Enterprise deleted a
manually-created uncommitted topic + its `.#` lock file during a startup routine.
Resulting standing safety rules:

- **Never delete anything under `dashboard/topics/` without explicit
  instruction.** Not during startup, not during "cleanup", not ever.
- **`.#<name>` files are editor lock files (symlinks), NOT junk.** Leave them
  alone; a "broken symlink" in the topics dir is almost always a stale lock.
- **Never directly `ls`/`Read`/`Glob`/`Grep` on dashboard files** — the
  CLI-only policy exists precisely so agents can't meddle with raw files.
- A WIP/empty topic file is the praetor's (or another ship's) in-flight work —
  never a cleanup target.

*(Ausführliche Incident-Doku + SQLite-Debug-Anleitung: siehe Git-History des
Fragments.)*
