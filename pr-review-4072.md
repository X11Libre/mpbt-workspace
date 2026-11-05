## Automated PR review — #4072

**Change:** `(master) xfree86: int10: remove unused/obsolete dprint()`
**Files:** 3 changed, +0 / −35 lines
**CI:** all checks green (SUCCESS across all lanes)

### Assessment

This is a **pure code-removal cleanup**: an unused/obsolete `dprint()` debug helper in `xfree86/int10/` that is no longer used. No behavior change, no production impact.

**Backport-worthy:** **No.** This is cleanup/refactoring of dead code — not a security fix, bugfix, crash fix, data corruption fix, or regression. It does not meet the backport criteria for any release line (`release/25.2`, `release/25.1`, `release/25.0`).

**NVIDIA driver ABI:** **No impact.** No public data-structure layout changes, no `_X_EXPORT` entry point removals or signature changes. Old NVIDIA blobs remain unaffected.

### Verdict

`bot-review-passed` — clean dead-code removal, all CI green, no ABI break, no backport needed.
