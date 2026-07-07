---
slug: dashboard-access-fully-encapsulated-via-starfleetctl-no-direct
title: "Dashboard access fully encapsulated via starfleetctl — no more direct file access by agents"
category: active
status: "**Directive issued by praetor, 2026-07-07 — unclaimed, not started.**"
---

Motivation: agents currently read/write `DASHBOARD.md` and `dashboard/themes/*.md` directly with
their own `Read`/`Edit`/`Write` tools (see [[split-dashboard-md-into-per-theme-files-a-thin-generated-ind]]
for how that's documented in `AGENTS.md` today), only going through `starfleetctl dashboard` for
`reindex`/`commit`. That's fine as long as every agent is a process on the same host with the same
git checkout on its local filesystem — but the fleet's declared direction ([[long-term-fleet-architecture-vision-bridge-command-frontend]])
is agents eventually spread across different hosts, where "just `Read` the file" stops making
sense. **Goal: no agent touches `DASHBOARD.md`/`dashboard/themes/*.md` as files at all — every
read and write goes through a `starfleetctl` subcommand**, so the access path is a single seam that
could later be repointed at a remote-backed implementation (an API server, a different host's
checkout, whatever) without changing anything on the agent-facing side.

**Where things already stand:** `starfleetctl dashboard` already has most of the needed surface —
`pull`/`show`/`write`/`commit`/`reindex` for the index, `theme list|show|write|new|commit` for
individual theme files (built for [[split-dashboard-md-into-per-theme-files-a-thin-generated-ind]],
see that file's implementation update). What's still open:
- `AGENTS.md`'s dashboard-workflow fragment currently *tells* agents to use `Read`/`Edit` directly
  on theme files and only reach for `starfleetctl` afterward (reindex/commit) — that guidance needs
  to change to CLI-only, and it needs checking whether `theme write` (whole-file replace) is
  actually ergonomic enough for the kind of targeted edits `Edit` does today, or whether it needs a
  patch/append mode too.
- Whether `theme commit <slug>` already handles a **brand-new** (untracked) theme file correctly
  (git add, not just add+commit of an already-tracked one) — verify, don't assume.
- No enforcement mechanism yet (nothing stops an agent from just using `Read`/`Edit` anyway) — decide
  if this stays convention-only (documented in `AGENTS.md`) or gets an actual check (e.g. a
  pre-commit hook flagging a diff to `DASHBOARD.md`/`dashboard/themes/*.md` not produced by
  `starfleetctl`).
- Explicitly **not** in scope yet: actually building any remote/multi-host backend — this directive
  is about closing the direct-file-access gap now, so that seam exists when multi-host work starts,
  not about building multi-host support itself.
