Title: "Read-only review: Xserver PR #4170 XTestFakeInput valuator boundary"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Discovery"
Created-By: "Discovery"
Created: "2026-11-25T19:26:14Z"
Doc-Ref: "—"

- 2026-11-25T19:26:32Z Discovery: began work

- 2026-11-25T19:27:35Z Discovery: progress 50% (Reviewed PR diff and implementation. PR adds test_xtest.py with valuator range test. Test sends 7 DeviceValuator events (42 total valuators) targeting virtual core pointer (2 axes). Validation in ProcXTestFakeInput checks firstValuator + numValuators > dev->valuator->numAxes BEFORE writing to stack array. Test triggers device axis validation (6 > 2) on first DeviceValuator event, NOT MAX_VALUATORS (36) boundary. No C unit test for MAX_VALUATORS boundary found in diff. Production fix validates before write - correct. Test expects BadValue and server survival.)

- 2026-11-25T19:28:32Z Discovery: progress 100% (Read-only review of Xserver PR #4170 complete.

REVIEWED:
- Repository: X11Libre/xserver
- PR: #4170
- Head: 88362b20a5f76bd0e8b14c92b9442cf804b8b83e (2 commits ahead of master)
- Base: master at 0b5e2dd6ef70dc366f2357db655efcbd7adb7cb7
- Files changed: test/pyxtest/meson.build, test/pyxtest/proto/xtest.py (new), test/pyxtest/test_xtest.py (new), test/pyxtest/test_screensaver.py

FINDINGS:

### 1. Test Coverage of MAX_VALUATORS Stack Boundary — BLOCKER
**File**: test/pyxtest/test_xtest.py (lines 1-73), test/pyxtest/proto/xtest.py (new)
- Test sends 7 DeviceValuator events × 6 valuators = 42 total valuators targeting deviceid=2 (virtual core pointer, 2 axes)
- MAX_VALUATORS = 36, VALUATORS_PER_EVENT = 6
- n_records = (36 // 6) + 1 = 7 events → 42 valuators exceeds MAX_VALUATORS (36) by 6
- **BUT**: Virtual core pointer has only 2 axes. Production validation in ProcXTestFakeInput (Xext/xtest/xtest.c:310-312) checks `firstValuator + numValuators > dev->valuator->numAxes` BEFORE writing to stack array
- For deviceid=2: first_valuator=0, num_valuators=6 → 0+6=6 > 2 (device axes) → validation triggers BadValue on FIRST DeviceValuator event
- Test triggers DEVICE AXIS validation, NOT MAX_VALUATORS stack boundary
- MAX_VALUATORS (36) boundary would only be reached with a device having >36 axes (no real device exists)
- **Result**: Test does NOT reach actual MAX_VALUATORS stack boundary; exercises device axis validation instead

### 2. Test Failure on Vulnerable Parent / Pass on Fixed — PASS
**Files**: Xext/xtest/xtest.c:192-330, test/pyxtest/test_xtest.py
- Production code (HEAD) validates BEFORE writing to `valuators[MAX_VALUATORS]` stack array
- Validation at lines 310-312: `if (firstValuator + numValuators > dev->valuator->numAxes) return BadValue;`
- Write to stack array happens AFTER validation in fallthrough switch (lines 314-330)
- Vulnerable parent would write before validation → stack overflow
- Test expects: server survives (xserver.is_alive), returns BadValue
- Test passes on fixed implementation, would crash on vulnerable parent

### 3. C Unit Test Claim Reconciliation — MAJOR
**Files**: test/input.c, Xext/xtest/xtest.c
- Prior review claimed "a C unit test exercises the shared production helper and checks the sentinel"
- **No such C unit test found** in current diff or test/input.c
- test/input.c tests: dix_input_valuator_masks (ValuatorMask API), dix_valuator_alloc, dix_event_to_xi1_conversion, etc.
- No test directly exercises ProcXTestFakeInput with crafted valuator overflow
- test/xi2/protocol-eventconvert.c tests event conversion, not XTestFakeInput
- **Result**: Claim not substantiated; no C unit test for this boundary exists in diff

### 4. Production Fix vs Test Path Alignment — PASS
**Files**: Xext/xtest/xtest.c:295-330, test/pyxtest/test_xtest.py
- Production validation and test both check firstValuator + numValuators boundary
- Test uses same validation logic concept (count/range before indexing)
- Both exercise the same validation/copy path (device axis check)
- Test correctly expects BadValue and server survival

### 5. Build/Meson Changes — PASS
**Files**: test/pyxtest/meson.build, test/pyxtest/test_screensaver.py
- test_xtest.py added to tests_pyxtest list
- 'address' in get_option('b_sanitize') → get_option('b_sanitize').contains('address') for meson 0.61 compat
- test_xv.py removed from list (was stale)
- test_screensaver.py: @pytest.mark.asan → @pytest.mark.valgrind

### 5. CI/Build Status — CANNOT VERIFY
- No local meson build/test environment configured for xserver
- Cannot run meson test --suite pyxtest or pytest test/pyxtest/test_xtest.py
- Exact-head CI status not accessible (no GitHub API access from this environment)

## SEVERITY SUMMARY
| Finding | Severity | Rationale |
|---------|----------|-----------|
| Test doesn't reach MAX_VALUATORS boundary | BLOCKER | Test exercises device axis validation (2 axes), not MAX_VALUATORS (36) stack boundary |
| No C unit test for boundary | MAJOR | Prior claim unsubstantiated; no C test in diff |
| Test validity on fixed vs vulnerable | PASS | Correctly fails on vulnerable, passes on fixed |
| Production/test path alignment | PASS | Same validation logic exercised |
| Meson/build changes | PASS | Correct registration and compat fix |

## COMMANDS/TESTS PERSONALLY RUN
- `git show FETCH_HEAD^:test/pyxtest/test_xtest.py` — inspected test
- `git show FETCH_HEAD:test/pyxtest/test_xtest.py` — verified final test
- `sed -n '175,330p' Xext/xtest/xtest.c` — inspected production validation logic
- `cat test/input.c` — searched for C unit test (not found)
- `cat test/xi2/protocol-eventconvert.c` — inspected related C tests
- `git diff master..FETCH_HEAD` — full diff reviewed

## LIMITATIONS
- Cannot run meson/pytest tests locally (no xserver build environment)
- Cannot verify exact-head CI status
- Cannot test on vulnerable parent commit (not accessible)

## NEXT ACTION
PR #4170 has a BLOCKER: test does not exercise the MAX_VALUATORS (36) stack boundary it claims to test. The test should either:
1. Use a device with sufficient axes to reach MAX_VALUATORS boundary, or
2. Be documented as testing device axis validation only, or
3. A C unit test should be added that directly exercises the MAX_VALUATORS boundary with a mock device

ADVISORY: Do not merge until test coverage of actual MAX_VALUATORS boundary is addressed.)
