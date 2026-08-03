---
slug: local/opencode-session-pruning
title: "opencode session pruning — Facts & gotchas"
order: 20
---

# opencode session pruning — Facts & gotchas

Script: `scripts/oc-prune-sessions` (dry-run by default, `--execute` to delete).

- **No built-in retention.** `OPENCODE_DISABLE_PRUNE` only disables in-session message
  compaction (PRUNE_MINIMUM=20k / PRUNE_PROTECT=40k in session/compaction.ts); sessions
  are never auto-deleted. DB grows unboundedly (~2.7 GB here).
- **Official delete path only.** Use `opencode session delete <id>` — goes through
  opencode's storage layer (WAL-safe), deletes child/forked sessions recursively.
  NEVER write DELETE statements against the live DB (opencode is the live WAL writer;
  corruption risk — Defiant warned about this).
- **`opencode session list` is project-scoped** (`listByProject` via `ctx.project.id`),
  so it only shows the current project's sessions (~12 here) — NOT all 163 in the DB.
  Use `opencode db "<sql>" --format tsv` for a global WAL-safe read of all sessions.
- **`opencode db` TSV gotchas:** output includes a header row (skip non-numeric
  `time_updated`); read columns in the order you SELECTed them; titles may contain any
  char except newline/tab (verified), but don't rely on it.
- **`session.time_updated` is reliable** (real ms epoch, used by the CLI as "updated").
- **Live-session detection is limited:** ships start via `opencode --prompt` (no
  `-s/--session` in argv, nothing in env), so pgrep can't find their session IDs.
  Practical protection = argv `-s/--session` detection + the idle filter (an actively
  used session always has recent time_updated, so it can never idle past the cutoff).
- **Archived sessions** (`time_archived NOT NULL`) should never be touched — exclude them.
- Orphaned children (parent row gone) are not listed by `session list` but still
  occupy space; handle by deleting roots (recursion) + direct deletion of orphans.
- Shell gotcha: `python3 -` reads the program from stdin — `json.load(sys.stdin)` would
  parse the heredoc, not the passed arg. Use `-c` or a file arg for the program and feed
  data separately.
