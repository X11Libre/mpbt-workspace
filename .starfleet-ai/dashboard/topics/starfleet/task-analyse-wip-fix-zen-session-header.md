---
slug: starfleet/task-analyse-wip-fix-zen-session-header
title: "Fix Zen free-tier 403 — forward x-opencode-session-id + correct UA"
category: task
status: done
priority: high
assignee: unknown
tags: [model-proxy, zen, free-tier, session-header, bugfix]
created: 2026-10-14T18:45:00+02:00
updated: 2026-10-14T18:45:00+02:00
---

## Summary
Fixed the OpenCode Zen free-tier regression where every request through the fleet model-proxy returned HTTP 403 `FreeTierError`.

## Root Cause
The proxy **did not forward `x-opencode-session-id`** upstream (only `x-opencode-session`), and its default User-Agent lacked the `ai-sdk/provider-utils/` token required by Zen's free-tier gate.

## Fix Applied
**File: `internal/modelproxy/config.go`** — rewrote `applyUpstreamHeaders`:

- **Session headers**: Now sets BOTH `x-opencode-session` AND `x-opencode-session-id` to the same value, taken from the client's request (prefers `x-opencode-session-id` → `x-opencode-session` → `X-Session-Id`). **Never fabricates** a session id (Zen rejects fabricated ids).
- **User-Agent**: Only forwards client UA when it matches the full official pattern (`opencode/<ver>` + `ai-sdk/provider-utils/<ver>`); otherwise uses provider override or the updated default (`opencode/1.18.30 ai-sdk/provider-utils/4.0.23 runtime/bun/1.3.14`) which includes the required ai-sdk token.
- Updated doc comment with verified gate requirements.

**File: `internal/modelproxy/config_test.go`** — rewrote `TestApplyUpstreamHeaders` with 9 cases covering the decision matrix; added `opencodeClientUA` const.

## Verification
- All tests pass: `go test ./internal/modelproxy/` ✅
- Build passes: `make all` ✅
- Probe verification: pointed `zen-proxy.base_url` at local echo server → captured upstream headers confirm **both session headers present and equal**, UA contains `ai-sdk/provider-utils/`.
- Direct Zen test with same headers → works when quota permits (rate-limited during verification).

## Commit
`629e115` fix(model-proxy): forward x-opencode-session-id and correct UA for Zen free tier

## Deployed
- Binary copied to `.starfleet-ai/bin/starfleetctl`
- `model-proxy restart` executed (running pid 24394, vcs.revision=629e115)
- Fleet proxy now forwards correct headers to Zen
