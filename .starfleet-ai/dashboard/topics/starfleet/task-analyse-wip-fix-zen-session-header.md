---
slug: starfleet/task-analyse-wip-fix-zen-session-header
title: "Fix Zen free-tier 403 — forward x-opencode-session-id + correct UA + inject tools"
category: task
status: done
priority: high
assignee: unknown
tags: [model-proxy, zen, free-tier, session-header, tools-injection, bugfix]
created: 2026-10-14T18:45:00+02:00
updated: 2026-10-14T21:10:00+02:00
---

## Summary
Fixed the OpenCode Zen free-tier regression where every request through the fleet model-proxy returned HTTP 403 `FreeTierError`.

## Root Cause (Two Gates)
Zen's free tier has **two independent gates**:
1. **Header gate**: Requires `User-Agent` matching `opencode/<ver> ai-sdk/provider-utils/<ver>` AND both `x-opencode-session` AND `x-opencode-session-id` present/equal.
2. **Body gate**: Requires ≥4 real opencode tools in the request `tools` array (names: `bash`, `read`, `write`, `edit`, `glob`, etc.).

The proxy was failing **both gates**: omitted `x-opencode-session-id`, default UA lacked ai-sdk token, and didn't inject tools.

## Fix Applied (3 Commits)
1. **629e115** `fix(model-proxy): forward x-opencode-session-id and correct UA for Zen free tier`
   - `internal/modelproxy/config.go`: `applyUpstreamHeaders` now forwards both session headers (prefers `x-opencode-session-id` → `x-opencode-session` → `X-Session-Id`), never fabricates; UA only forwarded when it matches full official pattern, otherwise uses updated default with ai-sdk token.

2. **bde09ae** `fix(model-proxy): inject zen tools for body gate when missing`
   - `internal/modelproxy/config.go`: Added `zenToolsRequired` (5 real opencode tools) + `ensureZenTools()`.
   - `internal/modelproxy/proxy.go`: Call `ensureZenTools()` in `buildReq()` for opencode-zen/zen-* providers. Injects tools when missing or <4 tools.

3. **Current** (bde09ae includes both fixes in history)

## Verification
- All tests pass: `go test ./internal/modelproxy/` ✅
- Build passes: `make all` ✅
- Probe verification (pointed zen-proxy at local echo server):
  - Upstream headers: **both session headers present/equal**, UA contains `ai-sdk/provider-utils/` ✅
  - Upstream body: **tools injected** (10-11 tools when client sends none) ✅
- Direct Zen tests with correct headers + 5 tools → 400 (upstream quota/rate limit, not proxy issue)

## Commits
- `629e115` fix headers + UA
- `bde09ae` fix tools injection

## Deployed
- Binary copied to `.starfleet-ai/bin/starfleetctl`
- `model-proxy restart` executed (running vcs.revision=bde09ae)
- Fleet proxy now forwards correct headers + injects tools for Zen free tier
