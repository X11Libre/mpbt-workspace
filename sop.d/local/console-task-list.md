---
slug: local/console-task-list
title: "Keep the console task list (todos) current"
order: 21
---

## Keep the console task list (todos) current

The agent console shows a live task list (the `todowrite` tool, rendered next to
the chat). Every ship must keep that list current while working, so the task the
ship is currently on is always visible at a glance on the console.

- **Create it at the start** of any multi-step task and set the first item to
  `in_progress` *before* doing the work.
- **Update it immediately after each step** — mark the finished item `completed`
  and set the next one `in_progress`. Do not batch updates: a stale list is
  worse than no list, because it misstates what is actually being worked on.
- **Exactly one `in_progress` item** while work remains.
- **Close it out**: set every item `completed` (or `cancelled` with a short
  reason) when the task ends.
- A single trivial action (one command, a lookup, a one-line answer) does not
  need a list.

Rationale: the console is the human's view into a background ship. Board
status/comms say *that* a ship is busy; the todo list says *what specifically*
it is doing right now, without having to read the transcript.

*(Praetor directive, 2026-10-12. Canonical fleet-wide home is the
`starfleet-instructions/working-practices-for-ships.md` fragment — owner
LaForge; this local copy makes it active in the workspace immediately.)*
