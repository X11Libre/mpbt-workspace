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
