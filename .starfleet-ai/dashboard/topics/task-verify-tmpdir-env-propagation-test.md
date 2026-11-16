Title: "Verify TMPDIR env propagation test"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-16T13:38:59Z"
Doc-Ref: "—"

Test that childEnv in launch.go correctly propagates TMPDIR/TMP/TEMP to ship subprocesses. Test commands: 1) starfleetctl session ship-run --name EnvTest --model cruiser --launch-type background 2) starfleetctl session attach EnvTest 3) In ship: echo $TMPDIR $TMP $TEMP (should show _WORK_/tmp/ship-EnvTest) 4) Verify opencode config allows ship tmp: cat .starfleet-ai/var/ships/EnvTest.opencode.json | jq '.permission.external_directory' 5) starfleetctl session stop EnvTest

- 2026-11-16T13:39:22Z Voyager: progress 0% (Test task created for verification AFTER implementation. Current audit was READ-ONLY - no implementation committed yet. Awaiting policy decision on temp-dir implementation (Option 1 recommended).)
