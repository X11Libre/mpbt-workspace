## Automated PR review — #4071

**Change:** `(master) xfree86: int10: drop never used SHOW_ALL_DEVICES code pathes`
**Files:** 1 changed, +0 / −77 lines
**CI:** all checks green (SUCCESS across all lanes)

### Assessment

This is a **pure code-removal cleanup**: dead `SHOW_ALL_DEVICES` code paths in `xfree86/int10/` that were never actually used. No behavior change, no production impact.

**Backport-worthy:** **No.** This is cleanup/refactoring of dead code — not a security fix, bugfix, crash fix, data corruption fix, or regression. It does not meet the backport criteria for any release line (`release/25.2`, `release/25.1`, `release/25.0`).

**NVIDIA driver ABI:** **No impact.** No public data-structure layout changes (no `ScrnInfoRec`, `ScreenRec`, `DeviceIntRec`, etc. modifications), no `_X_EXPORT` entry point removals or signature changes. Old NVIDIA blobs remain unaffected.

### Verdict

`bot-review-passed` — clean dead-code removal, all CI green, no ABI break, no backport needed.
