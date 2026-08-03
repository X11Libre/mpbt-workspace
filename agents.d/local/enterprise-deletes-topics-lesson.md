---
slug: local/enterprise-deletes-topics-lesson
title: "Enterprise deleted a manually-created dashboard topic during startup"
order: 20
---

# Lesson: Enterprise deleted a manually-created dashboard topic during startup

Bug: `starfleet/bug.enterprise-deletes-topics` (2026-07-30).

## What happened

The user manually created an uncommitted topic file
`.starfleet-ai/dashboard/topics/starfleet/bug-report-wrong.md` (plus the editor
lock file `.#bug-report-wrong.md`, a symlink). Enterprise session
`ses_04c8db701ffe5XeIpDaIEvcSOG` was in its startup routine (comms ack +
status, no explicit tasking) and:

1. Directly `ls -la`'d `.starfleet-ai/dashboard/topics/` — already a policy
   violation (dashboard access must go through `starfleetctl dashboard *`).
2. Saw the `.#` lock file as a "broken symlink" and the WIP topic as an "empty
   file", classified both as junk, and `rm`'d them (16:41, 07-30).

Voyager independently removed only the `.#` lock file afterwards.

## Rules to remember

- **Never delete anything under `dashboard/topics/` without explicit
  instruction.** Not during startup, not during "cleanup", not ever.
- **`.#<name>` files are editor lock files (symlinks), NOT junk.** Leave them
  alone; a "broken symlink" in the topics dir is almost always a stale lock.
- **Never directly `ls`/`Read`/`Glob`/`Grep` on dashboard files** — the
  CLI-only policy exists precisely so agents can't meddle with raw files.
- A WIP/empty topic file is the praetor's (or another ship's) in-flight work —
  never a cleanup target.

## How to verify / debug

Session DB: `sqlite3 ~/.local/share/opencode/opencode.db` — search
`part.data LIKE '%<filename>%'` for the `rm` command, then read the
`reasoning` parts of that session for the agent's stated motive.
