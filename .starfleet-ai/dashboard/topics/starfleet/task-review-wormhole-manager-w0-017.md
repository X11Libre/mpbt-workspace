---
title: "Wormhole manager review + blocker fixes (W0-017)"
status: done
category: active
owner: Discovery
tags: [starfleetctl, wormhole, review]
---

# Wormhole manager review + blocker fixes (W0-017)

Review of `work/wormhole-manager-w0-017` (commissioned by Enterprise) found
blockers A–G; all are fixed, committed atomically, pushed, and verified.
The independent review's follow-up directive (test gaps, plugin revert,
matrix accuracy) is also complete. Branch is merge-ready — NOT merged.

## Final state

- Branch: `work/wormhole-manager-w0-017` (mpbt-hq/starfleetctl)
- Remote HEAD == local HEAD: `3c2cc6f` (base `9bba345`, 16 commits on top)
- Every commit carries exactly one `Signed-off-by` (verified per commit).

## Phase 1 — blocker fixes (A–G)

| SHA | Subject |
|-----|---------|
| `3cd4643` | fix(wormhole): harden daemon startup against early exit and start races |
| `cd24fd1` | fix(wormhole): ignore runtime wormhole state dir in repo checkouts |
| `c67b71a` | fix(wormhole): release context timeouts in git helpers |
| `23695d7` | fix(wormhole): commit mail lifecycle transitions locally on read-only repos |
| `6684df0` | fix(wormhole): disable rename detection when rebasing onto remote |
| `cdedb67` | fix(wormhole): verify daemon identity before acting on recorded PID |
| `600285a` | test(wormhole): cover initial-scan crash convergence and transport guards |
| `88e6e10` | fix(plugin): preserve wormhole message metadata and exact ship resolution |
| `4d3a6a6` | docs(wormhole): sync daemon and read-only semantics with implementation |

## Phase 2 — review follow-up

| SHA | Subject |
|-----|---------|
| `293d2c0` | revert(plugin): restore starfleet-dispatch.ts to state at 9bba3450 |
| `c211843` | test(wormhole): prove read-only sync guarantees across real daemon restarts |
| `29c7d96` | test(wormhole): cover daemon startup/readiness semantics |
| `9745ad0` | test(wormhole): fail-closed identity for missing/invalid state files |
| `dcc2579` | test(wormhole): assert routing metadata survives into published envelope |
| `d41dd87` | test(wormhole): direct tests for work-dir path helpers and EnsureDir |
| `3c2cc6f` | docs(wormhole): sync requirement matrix with review follow-up tests |

- **Plugin restore**: `starfleet-dispatch.ts` byte-identical to `9bba3450`
  (net diff over base = 0 lines). Plugin topics stay parked for a separate
  integration phase.
- **Audit verdict**: implementation sound — all reviewer gaps were test
  gaps; no code fixes needed (stale-ready handshake race-free via
  ordering in `cli.go`, `resolveDaemon` fail-closed, per-cycle errors
  non-fatal).
- **Matrix accuracy**: 4 rows referenced non-existent tests (W0-017.5–.9 →
  new `TestPathHelpers`/`TestEnsureDir`); branch base corrected
  `500f254` → `9891c16` (merge-base); NOT TESTED count corrected 2 → 3;
  routing→envelope metadata arrow now directly asserted. All 52 test
  names referenced in the matrix verified to exist.

## Verification (exact HEAD `3c2cc6f`)

- `go test ./internal/wormhole/... -count=1`: ok 66.8s
- `go test ./internal/comms/... -count=1`: ok 3.5s
- `go test ./... -count=1`: all green except pre-existing unrelated
  `internal/session TestRunClientEnvShipTarget` (env-caused:
  `STARFLEET_TARGET` set by this fleet session; passes with
  `env -u STARFLEET_TARGET`; pre-existing at base).
- `go build ./...`, `go vet ./...`: clean.
- `make check-plugin`: esbuild bundle OK (tsc skipped — typescript not installed).
- `go test -C internal/wormhole .`: pass (run from a different cwd).
- CI: repo has NO workflows (0 check-runs for `3c2cc6f`) — local
  verification is the complete verification.

## Open items (not blockers)

- 3 requirements remain IMPLEMENTED + NOT TESTED (per matrix):
  GT-3 (timeout kills process), GT-6 (all git commands timed out),
  W0-026.3 `wormhole send` CLI (manual/integration only).

## Related

- `doc/wormhole.md`, `doc/wormhole-requirement-matrix.md` (in-repo, updated)
- Outer workspace commit `c54d67fba` (gitignore fix, parked files, reports)
- Final report to Enterprise: comms m17367; McKinley note m17369
- Superseded pre-review state `3ccca805` (consumer-lease variant, rejected
  design) is documented in `metux/wormhole-0/outbox/abschlussbericht.md`.
