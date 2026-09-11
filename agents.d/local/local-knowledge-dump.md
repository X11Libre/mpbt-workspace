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
   - `agents.d/starfleet-instructions/` — fleet coordination, comms, workflow
   - `agents.d/xlibre/`   — mpbt-workspace, build system, project rules
   - `agents.d/xlibre/`    — X server, drivers, protocol (future)

4. **On `mtx/agent-config`, auto-commit applies** — changes here are
   committed and pushed automatically per the auto-commit policy.

## Automatic feedback loop

After each (non-trivial) task, check your session for lessons learned and
add new entries here in the agents.d/local/ directory.

If you needed extra code (scripts, etc) for driving existing starfleet commands
(eg. github functions), analyze whether starfleetctl could use new commands
or options, so we need less extra scripting around it in the future, and create
dashboard tasks in the starfleet section.

## Standing lessons (aktive, wiederverwendbare)

### Git & Workflow
- **Bash backticks in `git commit -m` get command-substituted.** Always use `git commit -F - <<'EOF'` (quoted heredoc) for commit messages containing backticks/`$`.
- **`origin/master` can advance WHILE you work even mid-session.** Always re-fetch and rebase onto the CURRENT origin/master right before integrating; don't trust a ref read earlier in the session. Rebase conflicts then often involve another ship's adjacent feature — resolve by keeping BOTH lines.
- **add/add test-file conflicts:** resolve as a UNION — take my file, append the other side's content minus its header/import block; keep the import block ONCE. Run `gofmt -l` afterwards (unions leave duplicate blank lines).
- **`cp` FROM `/tmp/opencode/...` is BLOCKED** even though `/tmp/opencode/*` is allow-listed: the later `external_directory "**": deny` rule wins (last match wins). Write outputs into a workspace-relative path instead.

### starfleetctl deploy / daemons
- **Deploying a starfleetctl change:** build (`make all`) → commit+push (`master`) → `./starfleet-bootstrap` → `timer worker restart` + `web restart` → HTTP 200 → dashboard topic `done` + comms report.
- **Direct-binary deploy fallback** when `./starfleet-bootstrap` can't run cleanly: build in your OWN clean worktree at the rebased master, `rm -f` + `cp` the binary over `.starfleet-ai/src/starfleetctl/starfleetctl` (rm avoids text-file-busy), then `bootstrap --fix` + `sop reindex` with the NEW binary, then `web restart` + `timer worker restart` (both daemons keep OLD binary until restarted). Flag the dirty SRC tree to its owner.
- **Running ships keep OLD config/plugin in memory** after redeploy — only new/restarted sessions load the new version. Bootstrap + daemon restarts is NOT enough.
- **Plugin-only changes:** bump `PLUGIN_VERSION` so the fleet can verify rollout via dashboard/heartbeat.
- **Model-proxy pure-Go change deploy:** `make all` in the src tree then `model-proxy restart` alone is sufficient (restart re-execs the freshly built binary; no full bootstrap needed). The daemon never re-execs on its own.
- **`web restart` replaces the daemon even when web.pid is missing/stale** (kills `web start` procs via `/proc` cmdline). Verify end-to-end by corrupting web.pid (`echo 99999 > .starfleet-ai/var/web.pid && web restart` → fresh pid + HTTP 200).

### Comms / Dashboard
- **Broadcasts are fan-out per ship** (`msgs/<ship>/unseen/`, Target=<recipient>) — `msgs/all/` is gone. A self-targeted copy of your own broadcast is expected, not an error.
- **`comms migrate-broadcasts`** converts legacy `Target=="all"` records to per-ship copies; run it in the same deploy as a broadcast-model change. A ship that already acked is skipped (verify with `ls msgs/<ship>/unseen/<id>.json`).
- **`dashboard topic update <slug> --status done` is BROKEN** (parked `starfleet/bug-dashboard-topic-update-clobbers-fields`): ignores `--status` AND clobbers fields. Never use it; always `dashboard topic write <slug> <file>` (full file incl. frontmatter) + `dashboard topic commit`.
- **Sanctioned repair of a topic whose frontmatter is gone:** `dashboard topic write <slug> <file>` (full file incl. frontmatter) + `dashboard topic commit <slug> -m "..."` — never hand-edit topic files. Restore values from `git show <original-create-commit>:<path>`.
- **Dashboard commit helpers take a `push bool`, NOT `noPush bool`.** Passing `noPush` straight in silently INVERTS semantics (code does a pull+push). Always pass `!noPush`.

### opencode permission model
- **opencode reads per-model metadata from the `models` map in opencode.json, NOT from `/v1/models`.** Inject enriched metadata into the generated ship config, not the `/models` response.
- **The model-capability field is `tool_call`, NOT `tools`.** A top-level `tools` key means something else (global tool toggles).
- **opencode's permissive defaults are the baseline** — don't override with stricter per-launch-type rules unless there's a concrete bug. Workspace file tools must be `"**": "allow"` for ALL launch types (paths relative to worktree); `external_directory` handles outside paths.
- **`.starfleet-ai/` access** inside the workspace is gated by the workspace `** allow` rules, NOT `external_directory` (that only fires OUTSIDE the project working directory).
- **Go map-literal key collision pitfall:** `map[string]string{workspacePattern: "allow", "**": defaultRule}` with `workspacePattern = "**"` compiles fine (variable key, not a literal) but the second entry silently overwrites the first. Always double-check generated JSON for duplicate keys.
- **`session ship-run --name X -- <extra>` now hard-blocks extra args after `--`.** Use `starfleetctl run --name X --exec -- <args>` for config-generation checks.

### Model-proxy / upstreams
- **Zen free-tier gate needs UA + `x-opencode-session` + `x-opencode-client` + `x-opencode-project`** (as of 2026-09-09 for `big-pickle`). GitHub issue #42074 ("UA is what matters") is outdated — re-verify against the live gateway when upstream changes.
- **opencode sends its real session id to ANY openai-compatible base URL** as `X-Session-Id` + `X-Session-Affinity`. The proxy must MAP that → upstream `x-opencode-session` (Zen shards prefix cache on session id; a random id per request burns tokens). Synthesis only as fallback (health probes).
- **Streaming retries:** retry only on transport errors / 408/429/5xx before any data is sent; never append `[DONE]` mid-stream; if the stream dies without `[DONE]`, emit a structured `error` event (stream_interrupted) + `[DONE]` so clients don't hang.
- **`curl /v1/models` from the proxy regularly TIMES OUT** while it refreshes catalogs from overloaded upstreams — looks like a crash but is just slowness. `/v1/health` (404 fast) + `ss -ltnp` + `model-proxy status` confirm liveness.

### CI (xserver)
→ migriert in Skill `ci-platform` (Sektion "GH Actions cache & workflow-run gotchas"): GH-Actions-Cache branch-scoped/evictable, `gh run rerun --failed` kann Cache-Eviction NICHT reparieren (voller rerun nötig), delete-old-runs wipes history, Master-red+PR-green pattern.
→ Backport-Tooling-Gap (Multi-Commit-PR, TIP-only) migriert in Skill `backport` (Sektion Gotchas).

### Session / Ship lifecycle
- **A ship that crashed/exited BEFORE `session stop` arrives leaves a zombie heartbeat** on the board. `session stop <id>` on an already-dead ship is a no-op teardown that leaves heartbeat + files.
- **Sanctioned dead-ship completion:** `STARFLEET_SHIP_ID=<id> ./.starfleet-ai/bin/starfleetctl comms clear` (drops heartbeat; vanishes from `comms board`), then `rm` the leftover `var/ships/<id>.{log,pipe,stop-requested,opencode.json}`. All under the workspace.
- **Timer worker picks up new system verbs only after** bootstrap redeploys the binary AND `timer worker restart`.

### starfleetctl CLI gotchas
- **`task capture --title "…"` — the flag is `--title`, not a positional.** `reports submit` (plural), not `report submit`.
- **`starfleetctl run` hardcodes launchType "terminal"** — correct by design. For background use `session ship-run --launch-type background`.
- **`task progress <slug> <0-100> <note>`** already does log-append + comms status working coupling.
- **Web-based tasks detail:** full-text view does markdown rendering via `mdHtml()`.

### (Historie — erledigte Bugs, Referenz nur bei Bedarf)
- Frühere Bugs (default-model-fallback, web-PATH, permission-ask-hang, broadcast-ack, loadAllTopics, stale go/bin shadowing) sind BEHOBEN und durch andere Fragmente/working-practices abgedeckt. Details in Git-History/Commit-Messages.
