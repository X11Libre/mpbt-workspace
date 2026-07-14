---
name: task-capture
description: "Capture a fleet task into the dashboard (and optionally commission a free ship) purely by commandeering — never executing the task, never touching dashboard files directly. Use when asked to 'record a task', 'capture an aufgabe', 'track a to-do for the fleet', or 'assign a task to a free ship'."
---

# task-capture — pure commandeering of fleet tasks

Record a task for the fleet in the workspace dashboard, and optionally hand it
to a free ship. **This skill only commands — it never does the work.** Run it
and report back; do not start implementing the task yourself.

Designed to be driven by a small/fast model: the real logic lives in
`scripts/task-capture`, so the model only issues one deterministic command and
forwards the printed summary. No judgement, no file editing.

## Hard rules (non-negotiable)

1. **Never execute the task.** Capturing is the whole job. The assigned ship
   does the work later.
2. **No direct file access.** Never `Read`/`Edit`/`Write` `DASHBOARD.md` or
   `dashboard/themes/*.md`. All access goes through `starfleetctl dashboard
   theme …` (the helper script already does this).
3. **Messages to other ships / the praetor go in German** (agent-bus
   `tell`/`broadcast`). Code, commits, and doc files stay English.
4. **Report back** to the sender (e.g. Enterprise) via `agent-bus tell` with
   the printed summary after running.

## The one-liner (preferred — small-model friendly)

```sh
scripts/task-capture --title "<short task title>" \
    [--desc "<what needs doing / acceptance criteria>"] \
    [--slug "<override-slug>"] \
    [--assign [<ship>]] \
    [--no-push]
```

- `--assign` with **no ship name** → the script picks the first `idle`,
  non-stale ship from `agent-bus board --json` and commissions it.
- `--assign <ship>` → commission that specific ship.
- Without `--assign` → task is recorded as `offen` (open), no ship yet.
- `--no-push` → stage + commit locally but don't push to origin.

The script prints `task-captured: slug=… status=… assigned-to=…` — forward that.

## What the script does (so you can explain it)

1. Reserves a dashboard theme slug (`task-<derived>` unless `--slug` given) via
   `starfleetctl dashboard theme new` — refuses if the slug already exists
   (collision guard).
2. Optionally selects a free ship (idle + not stale) before writing.
3. Writes the task as a `category: active` theme (so it shows in DASHBOARD.md's
   "Aktive Themen") with task-specific frontmatter: `kind: task`,
   `created-by`, `created`, `assigned-to`, plus the description body.
4. `starfleetctl dashboard theme commit` — commits + pushes just that one file.
5. `starfleetctl dashboard reindex` + `dashboard commit` — refreshes the index.
6. If a ship was chosen: `starfleetctl agent-bus tell <ship>` with a German
   directive pointing at the dashboard theme.

## Manual fallback (only if the script is unavailable)

Use the same `starfleetctl` commands directly — never the files:

```sh
SLUG="task-my-task"
scripts/starfleetctl dashboard theme new "$SLUG" --title "<title>" --status "offen"
# build the theme content (frontmatter + body) in a scratch file under _WORK_/.tmp
scripts/starfleetctl dashboard theme write "$SLUG" _WORK_/.tmp/task.md
scripts/starfleetctl dashboard theme commit "$SLUG" -m "task: <title>"
scripts/starfleetctl dashboard reindex
scripts/starfleetctl dashboard commit -m "reindex: add task $SLUG"
# optional commission:
SHIP=$(scripts/starfleetctl agent-bus board --json | <pick idle,non-stale>)
scripts/starfleetctl agent-bus tell "$SHIP" "Neue Aufgabe für dich erfasst: <title> (Dashboard-Theme \`$SLUG\`). Bitte dort Details lesen und abarbeiten."
```
