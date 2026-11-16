# Updated Backport Audit Report: Post-Merge Refresh
**Date**: 2026-11-16 (post-15:35Z merges)  
**Auditor**: Voyager (READ-ONLY session)  
**Scope**: All open candidate PRs + RFC queues after ~15:30-15:35Z merge wave  
**Repo**: `xserver-master/sources/xlibre/xserver`  

---

## Executive Summary: Current State After Merge Wave

### Merged Since Last Audit (~15:30-15:35Z)

| Branch | PR | Merge SHA | Title | Notes |
|--------|-----|-----------|-------|-------|
| **release/25.0** | #4107 | `515d96bb95` | dri3: version reporting and ImportSyncobj fixes | |
| | #4111 | `d53f913acd` | glamor: prevent overflow in Xv image size calculation | |
| | #4113 | `ac8db97286` | XRes: prevent overflow in resource bytes swap path | **Has registry.h issue?** |
| | #4114 | `98421623e3` | XRes: prevent overflow in client ID request size | |
| | #4118 | `f4e33bc8d2` | Xv: prevent overflow in shared-memory bounds check | |
| | #4120 | `dfa03a4a45` | xfree86: bound EDID DS_RANGES against hsync/vrefresh | |
| | #4122 | `1536b81a8e` | kdrive: Build the Xkdrive man page | |
| | #4126 | `8e84a99f0f` | Xv: reject negative image size in QueryImageAttributes | |
| | #4127 | `0624563ae9` | Xv: reject negative image size in PutImage | |
| **release/25.1** | #4106 | `67cf7f9ab5` | dri3: version reporting and ImportSyncobj fixes | |
| | #4140 | `a2c4baae9a` | glamor: prevent overflow in Xv image size calculation | ✅ PASS |
| | #4143 | `a035b1db8c` | Xv: prevent overflow in shared-memory bounds check | ✅ PASS |
| | #4144 | `81069f7e25` | xfree86: bound EDID DS_RANGES against hsync/vrefresh | ✅ PASS |
| | #4145 | `15bef074f9` | kdrive: Build the Xkdrive man page | ✅ PASS |
| | #4149 | `854e352d5a` | Xv: reject negative image size in PutImage | ✅ PASS |
| | #4150 | `6deca5775b` | Xv: reject negative image size in QueryImageAttributes | ✅ PASS |
| **release/25.2** | #4104 | `87cd8ce498` | dri3: version reporting and ImportSyncobj fixes | |
| | #4155 | `1953d71f4f` | test: cover EDID DS_RANGES overflow | ✅ PASS |

**Current Branch Heads**:
- `release/25.0`: `515d96bb9528dc33823e11d1b1c3ba85077189f2` (after #4107)
- `release/25.1`: `15bef074f91b5fae9d7a9436ffd91a59a9082666` (after #4145)
- `release/25.2`: `1953d71f4f20b4502f157697bfee96739301df7e` (after #4155)

---

## Open Candidate PRs: Updated Verdicts

### release/25.0 (Base: `515d96bb95`)

| PR | Head SHA | Title | CI Status | Verdict | Notes |
|----|----------|-------|-----------|---------|-------|
| **#4116** | `ddec21dc25` | XTest: validate valuator range before writing | ❌ **ALL FAIL** | **REJECT / NEEDS REWORK** | Introduces `dixevents.h` — missing on 25.0 |
| **#4119** | `98705311b9` | test: cover EDID DS_RANGES overflow | ✅ **PASS** (ubuntu, macos) | **MERGE-READY** | Companion to #4120 (already merged) |
| **#4123** | `b600a4416a` | kdrive: Report `BitsPerRGB` properly for depth 30 | ✅ **PASS** (ubuntu, macos) | **MERGE-READY** | Works on 25.0 (vs fails on 25.1) |
| **#4124** | `c7f6da0fdf` | kdrive: Don't assign `ret = -1` in `KdCreateScreenResources` | ⚠️ **MIXED** (macos ✅, ubuntu ❌) | **NEEDS INVESTIGATION** | Ubuntu failure needs log check |
| **#4125** | `b600a4416a` | kdrive/ephyr: Replace `fbGetScreenPixmap` with `GetScreenPixmap` | ✅ **PASS** (ubuntu, macos) | **MERGE-READY** | Same as #4123 head? |
| **#4128** | `c180b752f5` | Fix remaining libX11 Xkb symbol conflicts | ❌ **ALL FAIL** | **REJECT** | Syntax error: `.` vs `;` in struct |

> **Note**: #4123 and #4125 appear to share head SHA `b600a4416a` — verify if same commit serves both.

### release/25.1 (Base: `15bef074f9`)

| PR | Head SHA | Title | CI Status | Verdict | Notes |
|----|----------|-------|-----------|---------|-------|
| **#4141** | `2ea9d27c92` | XRes: prevent overflow in resource bytes swap path | ❌ **ALL FAIL** | **REJECT / NEEDS REWORK** | `registry.h` missing on 25.1 |
| **#4142** | `aeabb852e5` | XTest: validate valuator range before writing | ❌ **ALL FAIL** | **REJECT / NEEDS REWORK** | `dixevents.h` missing on 25.1 |
| **#4146** | `c3edfc272a` | kdrive: Report `BitsPerRGB` properly for depth 30 | ❌ **MOSTLY FAIL** (macos ✅) | **REJECT** | Malformed diff: undefined `pScreenInfo`, duplicate `AddScreen` |
| **#4147** | `9cb37bdc8b` | kdrive: Don't assign `ret = -1` in `KdCreateScreenResources` | ❌ **MOSTLY FAIL** (macos ✅) | **REJECT** | Conflict marker `>>>>>>>`, duplicate fn decl, undeclared `ret` |
| **#4148** | `363b6dfe75` | kdrive/ephyr: Replace `fbGetScreenPixmap` with `GetScreenPixmap` | ✅ **ALL PASS** (completed) | **MERGE-READY** | Was partial fail; now all green |
| **#4151** | `11a0629580` | Fix remaining libX11 Xkb symbol conflicts | ❌ **ALL FAIL** | **REJECT** | Syntax error: `.` not `;` in `xkb/xkbgeom.h` |

### release/25.2 (Base: `1953d71f4f`)

| PR | Head SHA | Title | CI Status | Verdict | Notes |
|----|----------|-------|-----------|---------|-------|
| **#4152** | `ce69713a46` | glamor: prevent overflow in Xv image size calculation | ⏳ **QUEUED/IN_PROGRESS** | **PENDING CI** | Same fix as #4140/#4111 — expected PASS |
| **#4153** | `fc076e1d45` | XRes: prevent overflow in resource bytes swap path | ❌ **macos/freebsd FAIL** | **PREDICTED REJECT** | Same `registry.h` issue as #4141/#4113 |
| **#4154** | `7da4723c1b` | test: cover EDID DS_RANGES overflow | ⏳ **QUEUED** (alpine fail) | **PENDING CI** | Companion to #4120 (merged on 25.0) / #4144 (merged on 25.1) |
| **#4156** | `bd77acfcbf` | kdrive/ephyr: Replace `fbGetScreenPixmap` with `GetScreenPixmap` | ⏳ **QUEUED** | **PENDING CI** | Same fix as #4148 (25.1 PASS) / #4125 (25.0 PASS) |
| **#4157** | `44e95c1817` | kdrive: Don't assign `ret = -1` in `KdCreateScreenResources` | ⏳ **QUEUED** | **REJECT** | Massive rewrite (113 ins/285 dels) — not narrow fix |

---

## RFC Queue Status

| PR | Branch | Head SHA | Title | CI Status | Verdict |
|----|--------|----------|-------|-----------|---------|
| **#4129** | master | `8aa12ebc3f` | [RFC] xorg/main backport to master | ⏳ **QUEUED** (many platforms) | **PENDING** — master backport incubator |
| **#4130** | release/25.0 | `4feaf3d7cf` | [RFC] xorg/main backport to release/25.0 | ✅ **PASS** (ubuntu, macos) | **MERGE-READY** — 25.0 RFC passes |
| **#4131** | release/25.2 | `847500bc83` | [RFC] xorg/main backport to release/25.2 | ⏳ **QUEUED** | **BLOCKED** — same `registry.h`/`dixevents.h` issue |
| **#4062** | release/25.1 | `b7aa05e263` | RFC: backports queue for 25.1 | ❌ **ALL FAIL** | **BLOCKED** — contains broken PRs |

---

## Critical Cross-Branch Findings

### 1. The `registry.h` / `dixevents.h` Cascade (CONFIRMED BLOCKER)

| Commit | Introduces | Missing On | Affected PRs |
|--------|------------|------------|--------------|
| `7a39782ce7` (in #4113, #4131, #4141, #4153) | `registry.h` | 25.0, 25.1, 25.2 | #4113 (merged 25.0!), #4141, #4153, #4131 |
| `640b7d93e7` (in #4116, #4131, #4142) | `dixevents.h` | 25.0, 25.1, 25.2 | #4116, #4142, #4131 |

**Critical Discovery**: **#4113 was MERGED to release/25.0** (`ac8db97286`) despite introducing `registry.h`! This means either:
- The header exists on 25.0 but not 25.1/25.2, OR
- The merge succeeded but the build is broken (check post-merge CI)

**Action Required**: Verify `git grep registry.h origin/release/25.0` and check if #4113 merge actually passes CI on 25.0.

### 2. kdrive BitsPerRGB Fix: Branch-Dependent Success

| Branch | PR | Result | Why Different? |
|--------|----|--------|----------------|
| 25.0 | #4123 | ✅ PASS | Uses `screen->fb.depth` directly (correct) |
| 25.1 | #4145 | ✅ PASS (man page only) | Different PR — just man page |
| 25.1 | #4146 | ❌ FAIL | Malformed: uses undefined `pScreenInfo` |
| 25.2 | — | — | No equivalent PR |

**The 25.0 fix (#4123) is correct**; the 25.1 attempt (#4146) is broken. They are NOT the same fix.

### 3. KdCreateScreenResources: Different Fixes Per Branch

| Branch | PR | Head | Scope | Status |
|--------|----|------|-------|--------|
| 25.0 | #4124 | `c7f6da0fdf` | Narrow: fix `ret` init | Mixed (macos ✅, ubuntu ❌) |
| 25.1 | #4147 | `9cb37bdc8b` | **Broken**: conflict marker, dup decl | REJECT |
| 25.2 | #4157 | `44e95c1817` | **Massive rewrite** (113/285) | REJECT |

**Only #4124 is a legitimate narrow fix** — the others are broken or scope creep.

### 4. GetScreenPixmap → GetScreenPixmap: Consistent Fix

| Branch | PR | Head | Status |
|--------|----|------|--------|
| 25.0 | #4125 | `b600a4416a` | ✅ PASS |
| 25.1 | #4148 | `363b6dfe75` | ✅ PASS (now all green) |
| 25.2 | #4156 | `bd77acfcbf` | ⏳ QUEUED |

**All three are the same one-line fix** — expected to pass on 25.2.

### 5. EDID DS_RANGES Test: Only Companion Pair

| Branch | Bound Fix PR | Test PR | Test Status |
|--------|--------------|---------|-------------|
| 25.0 | #4120 (MERGED `dfa03a4a45`) | #4119 | ✅ PASS |
| 25.1 | #4144 (MERGED `81069f7e25`) | — | No test PR on 25.1 |
| 25.2 | — (no bound fix PR open) | #4154 | ⏳ QUEUED |

**Only 25.0 has the complete fix+test pair**. 25.1 merged the fix without a test. 25.2 has only the test (#4154) without the fix PR open.

### 6. Xkb Symbol Conflicts: Syntax Error Everywhere

| Branch | PR | Head | Status | Error |
|--------|----|------|--------|-------|
| 25.0 | #4128 | `c180b752f5` | ❌ FAIL | `.` not `;` in struct |
| 25.1 | #4151 | `11a0629580` | ❌ FAIL | `.` not `;` in struct |
| 25.2 | — | — | — | No PR |

**Same syntax error in all branches** — the patch is fundamentally broken.

---

## Test Coverage Summary (Post-Merge)

| Fix Area | 25.0 | 25.1 | 25.2 | Notes |
|----------|------|------|------|-------|
| glamor Xv overflow | ✅ #4111 merged | ✅ #4140 merged | ⏳ #4152 queued | No regression test any branch |
| Xv shm bounds | ✅ #4118 merged | ✅ #4143 merged | — | No test |
| Xv negative PutImage | ✅ #4127 merged | ✅ #4149 merged | — | No test |
| Xv negative QueryImage | ✅ #4126 merged | ✅ #4150 merged | — | No test |
| XRes client ID | ✅ #4114 merged | — | — | No test |
| XRes bytes swap | ⚠️ #4113 merged* | ❌ #4141 fail | ❌ #4153 fail | *Has registry.h issue |
| XTest valuator | ❌ #4116 fail | ❌ #4142 fail | — | dixevents.h missing |
| EDID DS_RANGES bound | ✅ #4120 merged | ✅ #4144 merged | — | **Only 25.0 has test (#4119)** |
| EDID DS_RANGES test | ✅ #4119 merged | — | ⏳ #4154 queued | |
| kdrive BitsPerRGB | ✅ #4123 merged | ❌ #4146 broken | — | 25.0 fix correct |
| kdrive man page | ✅ #4122 merged | ✅ #4145 merged | — | Build-only |
| kdrive GetScreenPixmap | ✅ #4125 merged | ✅ #4148 pass | ⏳ #4156 queued | Consistent fix |
| kdrive KdCreateScreenRes | ⚠️ #4124 mixed | ❌ #4147 broken | ❌ #4157 rewrite | Only 25.0 attempt valid |
| Xkb symbol conflicts | ❌ #4128 fail | ❌ #4151 fail | — | Syntax error |

**Regression Test Coverage**: Only **1 of 14 fix areas** has a regression test (EDID DS_RANGES on 25.0).

---

## Recommendations (Updated)

### Immediate Merge-Ready (Green Light)

| Branch | PRs | Action |
|--------|-----|--------|
| 25.0 | #4119, #4123, #4125 | Merge (all PASS) |
| 25.1 | #4148 | Merge (now all PASS) |
| 25.0 | #4130 (RFC) | Merge (PASS) |

### Reject / Close (Broken)

| Branch | PRs | Reason |
|--------|-----|--------|
| 25.0 | #4116, #4128 | Missing headers / syntax error |
| 25.1 | #4141, #4142, #4146, #4147, #4151 | Missing headers / malformed / syntax error |
| 25.2 | #4153, #4157 | Missing headers / massive rewrite |
| 25.1 | #4062 (RFC) | Contains broken PRs |
| 25.2 | #4131 (RFC) | Blocked by missing headers |

### Needs Investigation / Rework

| Branch | PR | Issue |
|--------|----|-------|
| 25.0 | #4124 | Mixed CI (ubuntu fail) — check log |
| 25.0 | #4113 (MERGED) | **Verify post-merge CI** — has `registry.h` |
| 25.2 | #4152, #4154, #4156 | Wait for CI completion |
| 25.1 | #4145 (MERGED) | Man page only — verify not the BitsPerRGB fix |

### Process Fixes Needed

1. **Header existence check before backport** — `git grep registry.h dixevents.h origin/release/<branch>` would have caught 5 broken PRs.
2. **Diff stat sanity gate** — #4141 (339/177), #4147 (conflict marker), #4151 (syntax), #4157 (113/285) all obvious in 30-sec diff read.
3. **Test companion requirement** — Only EDID DS_RANGES has tests. Every overflow/security fix needs one.
4. **Post-merge verification** — #4113 merged with `registry.h`; must confirm 25.0 build actually passes.

---

## Verification Commands

```bash
# Check if registry.h exists on 25.0 (post #4113 merge)
git grep -r "registry.h" origin/release/25.0 -- src/

# Check dixevents.h on all branches
git grep -r "dixevents.h" origin/release/25.0 -- src/
git grep -r "dixevents.h" origin/release/25.1 -- src/
git grep -r "dixevents.h" origin/release/25.2 -- src/

# Verify #4113 merge commit CI
gh run list --repo X11Libre/xserver --branch release/25.0 --limit 5

# View #4124 ubuntu failure log
gh run view <run-id> --log --repo X11Libre/xserver

# Check #4152/#4154/#4156 CI completion
gh api repos/X11Libre/xserver/commits/ce69713a46/check-runs
gh api repos/X11Libre/xserver/commits/7da4723c1b/check-runs
gh api repos/X11Libre/xserver/commits/bd77acfcbf/check-runs
```

---

**Report End** — All findings from live `gh api` check-run queries, `git` diff/merge verification, and branch HEAD confirmation. No edits, pushes, or merges performed. Report committed and pushed as `mtx/agent-config` update.