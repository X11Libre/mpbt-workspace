Title: "starfleetctl run --exec hinterlässt Heartbeat nach interaktivem /quit"
Category: starfleet
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Enterprise"
Created: "2026-09-07T11:57:17Z"
Doc-Ref: "—"

Bug: Ships, die via 'starfleetctl run --exec' gestartet und interaktiv per /quit beendet werden, bleiben auf dem Board stehen. execClientDirect (internal/session/run_cmd.go:206) setzt beim Start einen Heartbeat (Zeile 188), hat aber nach cmd.Run() (Zeile 262) keinen Exit-Cleanup (kein DoClear). Der termctl-run-Wrapper-Pfad (ship-run / run ohne --exec) hat hingegen den OnExit-Hook (launch.go:962), der crashed/cleared setzt.

Kontext: Discovery & Voyager waren per /quit beendet, blieben aber als blocked auf dem Board; verwaiste Heartbeats mussten manuell entfernt werden. Discovery.stop-requested vom 06.08. lag ebenfalls noch vor — auch session stop wurde nie von einem OnExit ausgelesen.

Fix: in execClientDirect nach cmd.Run() Cleanup analog zum OnExit-Hook ergaenzen: Exit-Code 0 -> DoClear() + DoRelease(name); sonst -> DoStatus(crashed, ...). Danach make + bootstrap deploy.
