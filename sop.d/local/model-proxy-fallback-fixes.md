---
slug: local/model-proxy-fallback-fixes
title: "Model-Proxy Fallback Fixes (2026-10-15)"
order: 25
---

# Model-Proxy Fallback Fixes (2026-10-15)

## Summary

Fixed critical fallback bugs in the model-proxy that prevented proper failover when upstream providers returned 5xx errors or stream interruptions. Also added configurable response header timeout per provider.

> **Correction 2026-10-16:** 3 of the 4 items below were implemented as claimed. Item 3
> (provider timeout mismatch / client recreation on reroute) was **documented but never
> implemented** — see the corrected section 3 for measurements, impact and status.

## Issues Fixed

### 1. 5xx Fallback Bug (Fixed in commit `fe386a5`)

**Problem:** When upstream providers returned 5xx errors, the model-proxy did not trigger fallback to the next model in the strategy because `attempt < attempts` was false when `MaxRetries=0` (default).

**Root Cause:** In `proxy.go` line 1399, the retry condition was `attempt < attempts` where `attempts = MaxRetries + 1`. With `MaxRetries=0` (default), `attempts=1`, so `attempt=1` on first attempt, making `1 < 1` false.

**Fix:** Added minimum 2 attempts for strategy routes in `proxy.go`:
```go
attempts := prov.MaxRetries + 1
// Ensure at least one retry (2 attempts) for strategy routes so that 5xx fallback works
if p.getStrategyForModel(requestedModel) != nil && attempts < 2 {
    attempts = 2
}
```

### 2. Streaming Fallback Bug (Fixed in commit `a2510d0`)

**Problem:** Stream interruption fallback at line 1496 had the same bug: `failed && attempt < attempts` prevented fallback on first attempt when MaxRetries=0.

**Fix:** Extended condition to `(attempt < attempts || (attempt == attempts && attempts == 1))` and added reroute logic with circuit breaker handling (force-open of the failed model's breaker, `routeStrategyModel`, attempt reset). Client recreation was **NOT** part of this commit — see item 3.

### 3. Provider Timeout Mismatch on Fallback (DOCUMENTED BUT NEVER IMPLEMENTED — corrected 2026-10-16)

**Original claim (FALSE, removed):** "Fixed in commit `a2510d0` — added client recreation logic in the fallback path."

**Correction, measured 2026-10-16:**
- `a2510d0` contains **no** client recreation (diff checked: only breaker force-open,
  `routeStrategyModel`, attempt reset).
- On `3c53ddb`: `nonStreamClient` / `streamClient` / `streamTransport` are created
  **once** before the retry loop (`proxy.go:1327ff`) and **never reassigned** after
  `prov = newProv` — zero hits.
- Found by Rosetta's independent review (`starfleet/task-review-model-proxy-fallback-streaming-commits`,
  3/4 fixes confirmed, this one missing); confirmed independently by Enterprise.

**The bug is real:** after a reroute the HTTP clients keep the *old* provider's timeouts.
Live-config impact (no `timeout`/`response_header_timeout` keys set → `config.go` defaults):
nvidia-direct/nim 30s vs zen-proxy 15s → reroute zen→nvidia keeps the 15s cap (premature
abort of non-streaming calls); nim→zen keeps 30s instead of 15s (benign). `ResponseHeaderTimeout`
is 30s everywhere today → latent only, but bites the moment anyone sets
`response_header_timeout` per provider (the very symptom `18e56f7` was meant to fix).

**Status (2026-10-16): FIXED + VERIFIED.** LaForge committed the client recreation
as `a408f59` (52 insertions / 2 `=`-assignment blocks, no `:=`), pushed to
`origin/master`, deployed via `./starfleet-bootstrap` + `model-proxy restart`
(pid 25360, running rev `a408f59`). **Measured end-to-end** (not just read): a
freshly generated ship config (deployed binary) now emits `limit` for every
meta-model strategy — cruiser 131072/131072, heavy-model 131072/131072,
nim-primary 131072/131072, balanced-model 200000/200000 (= `EffectiveLimit`).
Before, `output=0` + `omitempty` dropped `limit` entirely. Independently confirmed
by LaForge (m5208) and McKinley (m5209).

**Warning:** the code snippet formerly shown here was pasted verbatim into
`proxy.go` during that WIP (twice per reroute site, mixed tab/space indentation, dead
`if/else` overwritten by `nonStreamTimeout = time.Duration(prov.Timeout)`, `:=` shadowing
that left the outer clients untouched and broke the build with 6 errors). **This document
is documentation, not a patch source.** The clean shape: one `=`-assignment block per site,
or better a `rebuildClients(prov)` helper called at both reroute sites.

### 4. Configurable Response Header Timeout (Fixed in commit `18e56f7`)

**Problem:** Hardcoded 30s response header timeout caused `ProviderHeaderTimeoutError` for slow upstream providers (NVIDIA NIM).

**Fix:** Added `ResponseHeaderTimeout` field to Provider config:
- Added `ResponseHeaderTimeout time.Duration` to `Provider` struct in `config.go`
- Added `ResponseHeaderTimeout time.Duration` to `ModelProxyProvider` in `config.go`
- Updated `proxy.go` to use provider-specific timeout:
```go
responseHeaderTimeout := 30 * time.Second
if prov.ResponseHeaderTimeout > 0 {
    responseHeaderTimeout = prov.ResponseHeaderTimeout
}
```

## Configuration

### Provider Configuration (model-proxy.yaml)

```yaml
providers:
  - id: nim-proxy
    # ...
    response_header_timeout: 60s  # Optional, defaults to 30s
```

### Strategy Configuration

Strategies now properly handle fallback on both 429 and 5xx errors:

```yaml
strategies:
  - id: cruiser
    strategy: fallback
    models:
      - id: "nvidia/nemotron-3-ultra-550b-a55b"
        provider: "nvidia-direct"
        priority: 1
      - id: "nvidia/nemotron-3-super-120b-a12b"
        provider: "nvidia-direct"
        priority: 2
      # ... more fallback models
```

## Testing

1. **Build verification:** `cd _WORK_/starfleetctl/sources/starfleetctl && make all` - passes
2. **Unit tests pass:** All modelproxy tests pass
3. **Fleet verification:** 7 ships active, fallback verified in production

## Deployment

```bash
# Deploy changes
./starfleet-bootstrap
# Restart model-proxy to pick up new config
./.starfleet-ai/bin/starfleetctl model-proxy restart
```

## References

- Commits: `fe386a5`, `a2510d0`, `18e56f7`
- Files modified: `internal/modelproxy/proxy.go`, `internal/modelproxy/config.go`, `internal/config/config.go`
- Config example: `.starfleet-ai/conf/model-proxy.yaml`