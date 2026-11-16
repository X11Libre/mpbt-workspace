Title: "Verify TMPDIR env propagation test"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-11-16T13:38:59Z"
Assigned-To: "Voyager"
Doc-Ref: "—"
Slug: task-verify-tmpdir-env-propagation-test

Test that childEnv in launch.go correctly propagates TMPDIR/TMP/TEMP to ship subprocesses. Test commands: 1) starfleetctl session ship-run --name EnvTest --model cruiser --launch-type background 2) starfleetctl session attach EnvTest 3) In ship: echo $TMPDIR $TMP $TEMP (should show _WORK_/tmp/ship-EnvTest) 4) Verify opencode config allows ship tmp: cat .starfleet-ai/var/ships/EnvTest.opencode.json | jq '.permission.external_directory' 5) starfleetctl session stop EnvTest
