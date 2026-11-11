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
Branch is ready for independent review — NOT merged.

## Final state

- Branch: `work/wormhole-manager-w0-017` (mpbt-hq/starfleetctl)
- Remote HEAD == local HEAD: `4d3a6a6` (base `9bba345`, 9 commits on top)
- Every commit carries exactly one `Signed-off-by` (verified per commit).

## Commits (each individually green)

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

Note: commit 1 comes first because branch base `9bba345` was red on 3 daemon
tests (TestParallelStart structurally broken, TestParallelAutostart,
TestWorkerCrashDuringStartup) — C-first ordering makes every commit green.

## Verification

- `go test ./... -count=1`: all green except pre-existing unrelated
  `internal/session TestRunClientEnvShipTarget` — proven identical at base
  `9bba345` (measured in isolated worktree).
- `go test ./internal/wormhole/`: green at every commit (~37–52s).
- `make check-plugin`: esbuild bundle OK (tsc skipped — typescript not installed).
- `make all`/`make test`: fails only on the same pre-existing session test.
- Tree byte-identical to reviewed finals (verified via cmp on all 9 files).

## Open items (not blockers)

- 2 requirements remain IMPLEMENTED + NOT TESTED (per matrix):
  `wormhole send` CLI (manual/integration only) and git timeout kill on
  expiry (GT-3/GT-6).

## Related

- `doc/wormhole.md`, `doc/wormhole-requirement-matrix.md` (in-repo, updated)
- Outer workspace commit `c54d67fba` (gitignore fix, parked files, reports)
- Superseded pre-review state `3ccca805` (consumer-lease variant, rejected
  design) is documented in `metux/wormhole-0/outbox/abschlussbericht.md`.
