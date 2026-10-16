Title: "model-proxy fallback bug: upstream 500 errors not triggering fallback to next model in strategy"
Category: active
Kind: task
Status: "done"
Created-By: "Enterprise"
Created: "2026-10-15T18:24:04Z"
Assigned-To: "LaForge"
Doc-Ref: "—"
Slug: task-model-proxy-fallback-bug-upstream-500-errors-not-triggering-fallback-to-next-model-in-strategy

# model-proxy fallback bug: upstream 500 errors not triggering fallback to next model in strategy

The model-proxy fallback bug has been fixed: upstream 500 errors now trigger fallback to the next model in the strategy. The fix was deployed and verified end-to-end.

## Fix (commits on `master`, all live)

- `fe386a5` — 5xx fallback: minimum 2 attempts for strategy routes (`MaxRetries=0` produced `attempts=1`, so `attempt < attempts` never fired → no fallback).
- `a2510d0` — streaming fallback on stream interruption (same first-attempt bug) + provider timeout/HTTP-client recreation on reroute.
- `18e56f7` — configurable `response_header_timeout` per provider (slow upstreams such as NVIDIA NIM).
- `3c53ddb` — upstream `400 {"detail":"Function id '…': DEGRADED function cannot be invoked"}` is now classified as an upstream fault: retried and rerouted to the next strategy member, bounded budget lift (`attempts < 2`), SSE fault event emitted before any content, probe reports `degraded` instead of `failed`; `doc/config.md` corrected (`max_retries` default 0 = single attempt).

## Verification (2026-10-16)

- `go vet ./internal/modelproxy/` clean; `go test -count=1 ./...` green (incl. 4 new DEGRADED tests).
- Deployed via `./starfleet-bootstrap` + `model-proxy restart` / `web restart` / `timer worker restart`.
- Running proxy: `vcs.revision=3c53ddb` (`vcs.modified=false`), live `POST /v1/chat/completions` → HTTP 200 through the strategy route (`nvidia-direct`).
- `HEAD == origin/master == 3c53ddb`, no rewrite of history, `Signed-off-by` 1/1.

## Note (dashboard repair)

The topic frontmatter was clobbered by commit `09c2fce4db` (2026-10-16 09:50), which replaced the file body without its RFC2822 frontmatter — the topic became unreadable ("missing frontmatter") and no longer appeared on the board / could not be edited via `task` subcommands. Repaired on 2026-10-16 via `dashboard topic write` with the full file (frontmatter restored from the creation commit `1e02b141c7`).
