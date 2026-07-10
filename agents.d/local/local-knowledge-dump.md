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
