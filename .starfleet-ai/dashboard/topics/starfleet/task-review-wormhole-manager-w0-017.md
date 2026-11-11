---
title: "Wormhole manager review + blocker fixes (W0-017)"
status: done
category: active
owner: Discovery
tags: [starfleetctl, wormhole, review]
---

# Wormhole manager review + blocker fixes (W0-017)

Review of `work/wormhole-manager-w0-017` (commissioned by Enterprise) found
blockers A–G; all fixed and verified. Review follow-up (test gaps, plugin
revert, matrix accuracy) complete. Final merge-readiness pass (PID fail-closed,
sync push_retries, locale-independent git output, full audit) complete.
Branch is merge-ready — NOT merged (awaiting Praetor merge decision).

## Final state

- Branch: `work/wormhole-manager-w0-017` (mpbt-hq/starfleetctl)
- Remote HEAD == local HEAD: `65c0dfa` (base `9bba345`, 21 commits on top)
- Every commit carries exactly one `Signed-off-by` (verified per commit).
- Plugin `starfleet-dispatch.ts` byte-identical to baseline
  (blob `7527e34589d3e938bf110cfdca6c40dbfa16e27c`, re-verified at final HEAD).

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
| `c211843` | test(wormhole): daemon restart over multiple RO cycles |
| `29c7d96` | test(wormhole): startup sync / sync failure / stale ready marker |
| `9745ad0` | test(wormhole): fail-closed on unverified PID files |
| `dcc2579` | test(wormhole): assert routing metadata in wormhole envelope |
| `d41dd87` | test(wormhole): direct tests for path helpers and EnsureDir |
| `3c2cc6f` | docs(wormhole): sync requirement matrix with review follow-up tests |

## Phase 3 — final merge-readiness corrections

| SHA | Subject |
|-----|---------|
| `903af0c` | fix(wormhole): fail closed on present-but-unusable pid files |
| `281d001` | fix(wormhole): honor sync.push_retries in one-shot sync |
| `b353acd` | fix(wormhole): force C locale for git invocations |
| `65c0dfa` | docs(wormhole): document pid-file refusal, push_retries and locale fixes |

Findings of the final pass:

1. **PID fail-closed gap (fixed)**: `readPIDFile` treated unreadable/
   unparseable/empty/non-positive pid files as "no daemon registered" —
   `start` could spawn a second worker on top of a recorded instance and
   `stop` silently reported "not running". Now a hard refusal (no spawn, no
   signal, runtime files preserved, `status` surfaces the reason); only a
   genuinely absent pid file means "not running" (W0-018.16,
   `TestUnverifiedPIDFilesFailClosed`).
2. **`wormhole sync` ignored `sync.push_retries` (fixed)**: hardcoded 3,
   diverging from the daemon RunLoop. Retry count now comes from the single
   config load inside `processPendingMessages` (W0-026.2,
   `TestSyncUsesConfiguredPushRetries`: with `push_retries=0` exactly one
   push attempt against a rejecting remote).
3. **Locale-dependent git output classification (fixed)**: git localizes
   diagnostics (de_DE host: "Fehler beim Versenden einiger Referenzen"),
   `isNonFastForward` matches English phrases only — recoverable push
   rejections were misclassified as permanent on localized hosts. All
   GitSync git invocations now run with `LC_ALL=C` (pre-existing `LC_ALL`
   filtered: duplicate env entries resolve to the first occurrence)
   (GT-7). Found by the new test on this de_DE.UTF-8 host.

Audit beyond the three fixes: daemon lifecycle/readiness/stop/restart/
autostart/PID identity, crash recovery incl. incomplete maildir transitions,
RO multi-cycle + real daemon restarts, git lock/fetch/rebase/push-retries,
exact staging, PostExternal idempotency/crash recovery, message ID/Type/
ReplyTo/payload preservation, attachment rejection, invalid-message
handling, config validation vs docs (push_retries 0–10 enforced and
documented) — all backed by existing tests; matrix unchanged for those rows
(no artificial upgrades; NOT TESTED rows remain W0-026.3, GT-3, GT-6).

## Verification (exact final HEAD `65c0dfa`)

- `go test -C internal/wormhole -count=1 .` — ok (63.6s)
- `go test -C internal/comms -count=1 ./...` — ok (3.4s)
- `go test ./...` — only pre-existing env-caused failure
  `internal/session TestRunClientEnvShipTarget` (fleet session exports
  `STARFLEET_TARGET=Enterprise`; passes with `env -u STARFLEET_TARGET`)
- `go build ./...`, `go vet ./...`, `gofmt` — clean
- `make check-plugin` — esbuild bundle check OK (tsc skipped: typescript not
  installed on this host, pre-existing condition)
- CI: repository has no CI workflows (only GitHub-internal "Dependency
  Graph" dynamic workflow); 0 check-runs for `65c0dfa` — local verification
  is the complete verification
- Pushed: `3c2cc6f..65c0dfa work/wormhole-manager-w0-017`

## Remaining limitations (documented, not blockers)

- `wormhole send` CLI (W0-026.3), timeout process-kill (GT-3) and full
  command-timeout coverage (GT-6) remain manual/NOT TESTED — unchanged.
- RunLoop keeps interval/startup-sync from the start-time config;
  repositories, timeouts and retries are re-read per cycle (pre-existing
  design).
- tsc type check unavailable on this host (esbuild check covers bundle
  integrity).

Merge-ready: yes — all review blockers fixed, final corrections verified on
exact HEAD, plugin untouched vs baseline. Merge decision belongs to the
Praetor; Discovery does NOT merge.
