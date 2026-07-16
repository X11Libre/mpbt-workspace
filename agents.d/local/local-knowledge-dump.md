---
slug: local/local-knowledge-dump
title: "Local knowledge dump — session discoveries"
order: 10
---

## Local knowledge dump

This directory (`agents.d/local/`) is a **local dumping ground** for
insights, discoveries, quirks, and conventions learned during agent
sessions — anything that doesn't yet belong in the structured
`project/`, `starfleet/`, or eventual `xlibre/` taxonomies.

### Rules

1. **Dump first, sort later.** If you discover something during a
   session that is worth remembering, create or append to a file here
   immediately. Don't worry about where it should ultimately live.

2. **No cross-ship guarantees.** Other ships in the fleet may write
   here too, but there is no ordering, deduplication, or review
   process. Treat this as scratch space.

3. **Promotion path.** When a local insight proves itself stable
   (survived multiple sessions, referenced from other fragments), it
   should be moved to the appropriate taxonomy directory:
   - `agents.d/starfleet/`  — fleet coordination, agent-bus, workflow
   - `agents.d/project/`   — mpbt-workspace, build system, project rules
   - `agents.d/xlibre/`    — X server, drivers, protocol (future)

4. **On `mtx/agent-config`, auto-commit applies** — changes here are
   committed and pushed automatically per the auto-commit policy.

## starfleetctl: single local clone (under .starfleet-ai/)

There is now exactly **one** starfleetctl source clone:

- `.starfleet-ai/src/starfleetctl/` — the source tree the workspace binary
  symlink (`.starfleet-ai/bin/starfleetctl`) is built from. Managed by
  `./starfleet-bootstrap`.

The former second clone (`_WORK_/starfleetctl/`, its own mpbt solution —
`cf/starfleetctl/`, `run-fetch.starfleetctl`, `run-build.starfleetctl`) was
removed on 2026-07-13, along with `scripts/starfleetctl` (the thin wrapper
that used to exec `.starfleet-ai/bin/starfleetctl`). The binary at
`.starfleet-ai/bin/starfleetctl` is now invoked directly.

### Workflow (standing, since 2026-07-13)

1. Edit fragments/code in `.starfleet-ai/src/starfleetctl/`, commit, push.
2. Rebuild: `cd .starfleet-ai/src/starfleetctl && go build -o starfleetctl ./cmd/starfleetctl`
   (or just re-run `./starfleet-bootstrap`).
3. Roll out in the workspace: `./.starfleet-ai/bin/starfleetctl bootstrap --fix`.

Gotcha: `bootstrap` installs from the **binary's embedded** fragments
(`//go:embed all:fragments`), not the source tree — so a rebuild (step 2)
is mandatory after any fragment edit, or `bootstrap --fix` silently clobbers
local edits with the stale embedded copy.
