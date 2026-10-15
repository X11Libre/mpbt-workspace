# Model-Proxy Fallback Fixes (2026-10-15)

## Summary

Fixed critical fallback bugs in the model-proxy that prevented proper failover when upstream providers returned 5xx errors or stream interruptions. Also added configurable response header timeout per provider.

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

**Fix:** Extended condition to `(attempt < attempts || (attempt == attempts && attempts == 1))` and added full reroute logic with circuit breaker handling and client recreation.

### 3. Provider Timeout Mismatch on Fallback (Fixed in commit `a2510d0`)

**Problem:** When falling back to a different provider type (e.g., nvidia-direct → zen-proxy), HTTP clients retained original provider's timeout settings.

**Fix:** Added client recreation logic in fallback path:
```go
// Recreate HTTP clients with new provider's settings
if prov.Type == "opencode-zen" {
    nonStreamTimeout = 15 * time.Second
} else {
    nonStreamTimeout = 30 * time.Second
}
nonStreamTimeout = time.Duration(prov.Timeout)
// ... recreate nonStreamClient and streamClient with new provider settings
```

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