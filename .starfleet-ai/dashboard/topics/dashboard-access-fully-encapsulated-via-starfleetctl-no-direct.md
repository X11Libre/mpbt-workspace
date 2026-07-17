---
slug: dashboard-access-fully-encapsulated-via-starfleetctl-no-direct
title: "Dashboard access fully encapsulated via starfleetctl — no more direct file access by agents"
category: active
status: "open"
assigned-to: ""
created-by: ""
created: ""
doc_ref: ""
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

**2026-07-07 (Constellation, m0123): all four open questions resolved, CLI-only guidance landed.**
- **`AGENTS.md` guidance changed to CLI-only** (`agents.d/working-practices-standing-instructions-for-agents.md`,
  commit `5b7cc3c`): agents must not `Read`/`Edit`/`Write` `DASHBOARD.md`/`dashboard/themes/*.md`
  directly anymore. **Ergonomics for targeted edits:** `theme write`'s whole-file replace is fine —
  no patch/append mode needed. The documented pattern is `theme show <slug> > /tmp/t.md`, edit that
  local scratch copy with the normal editing tool, then `theme write <slug> /tmp/t.md` + `theme
  commit <slug> -m "<msg>"`. This theme file itself was updated that way, eating its own dog food.
- **`theme commit` on a brand-new untracked file: verified correct, not assumed.** Built a scratch
  git repo, ran `theme new` + `theme commit` against it — `git add <path>` (which `DoThemeCommit`
  already calls) stages new files exactly like modified ones; the commit showed `create mode 100644`
  and left the working tree clean. No code change needed here, just confirmation.
- **Found and fixed a real bug while verifying:** `DoReindex` was hardcoding "Edit the theme file
  directly (Read/Edit as always)" straight into every regenerated `DASHBOARD.md` — a leftover from
  before this directive that actively contradicted the new policy every time anyone ran `reindex`.
  Fixed in `starfleetctl` commit `bdad0a7` (also documented the previously-undocumented `theme`
  subcommand family in that repo's own `README.md`, which never got added when `theme` shipped).
  Propagated into the real `DASHBOARD.md` via `dashboard reindex` — visible above once this file's
  own change lands and gets re-indexed.
- **Enforcement: convention-only for now, deliberately not building a check yet.** Considered a git
  pre-commit hook flagging any diff to these paths not produced by `starfleetctl` (e.g. an env var
  the Go binary sets around its own internal `git commit` calls, which the hook requires), but that
  adds real complexity/false-positive risk for a convention that's minutes old and hasn't caused a
  single actual violation yet. A repo-level `.claude/settings.json` permission deny was also
  considered and rejected: this workspace has no committed `.claude/settings.json` at all today
  (only the praetor's personal `~/.claude/settings.json`, which is user- and machine-scoped, not
  fleet-portable, and would affect every *other* project on that machine too — wrong blast radius).
  **Revisit if:** an agent is actually caught hand-editing these files after this date, at which
  point the pre-commit-hook-with-marker-env-var approach above is the recommended next step, not a
  fresh design pass.
- **Still explicitly out of scope**, unchanged from the original directive: no remote/multi-host
  backend — this closes the direct-file-access gap so that seam exists later, nothing more.
