---
slug: rename-dashboard-theme-to-topic-terminology
title: "Rename DASHBOARD \"theme\" terminology to \"topic\" (dashboard/themes/ dir + starfleetctl theme subcommand)"
category: parked
noted_by: "praetor, 2026-07-07"
since: "2026-07-07"
---

English "theme" reads to most people as GUI/visual theming (dark mode, color scheme, etc.), not as
"Thema" in the German sense of "topic/subject/initiative" that this dashboard actually means (see
`DASHBOARD.md`'s own header: "themes/initiatives — not individual PRs/tasks"). "topic" is the
better English fit; "tasks" was considered and rejected — the whole point of this dashboard is
*not* to be a granular task tracker (that's GitHub issues/PRs, or the `TaskCreate` tool), so
"tasks" would actively mislead about scope.

**Deliberately sequenced after [[dashboard-access-fully-encapsulated-via-starfleetctl-no-direct]]
(m0123, in progress 2026-07-07, Constellation), not in parallel with it** — that work is actively
touching the same directory (`dashboard/themes/`) and the same `starfleetctl dashboard theme *`
subcommand names; renaming underneath it now would just create merge churn for no reason. Do this
once m0123 has landed.

**Scope when picked up:**
- Directory: `dashboard/themes/` → `dashboard/topics/` (all existing files `git mv`d, not
  recreated, to keep history).
- `starfleetctl`'s `dashboard theme list|show|write|new|commit` → `dashboard topic ...` (separate
  repo, `mpbt-hq/starfleetctl` — coordinate the rename there too, not just doc references here).
- Every cross-reference: `AGENTS.md`/`DASHBOARD.md` prose, this repo's own theme-file bodies
  (several already say "Theme-Datei"/"theme file" inline).
- **Transition aid raised by the praetor:** a temporary symlink (`dashboard/themes` →
  `dashboard/topics`, and/or a `theme` subcommand alias forwarding to `topic`) so anything not yet
  updated (open PRs, another ship's stale context, muscle memory) keeps working during the
  changeover instead of hard-breaking on rename day. Decide at implementation time whether that's
  worth the added complexity or whether a single atomic rename (small enough repo/tool) is simpler.
