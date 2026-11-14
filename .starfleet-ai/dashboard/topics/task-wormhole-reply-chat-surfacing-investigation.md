Title: "Wormhole reply chat surfacing investigation"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-11-14T16:09:09Z"
Doc-Ref: "—"

Trace outbound Comms->Wormhole send path and inbound Wormhole->Comms reply path to identify integration point for surfacing wormhole replies in originating chat/session without duplicate sessions or turns.

- 2026-11-14T16:30:04Z Voyager: progress 40% (Investigation in progress. HEAD 7ece6206e34f91febb335477760c5f89e2ab2e7f (work/wormhole-manager-w0-017, pushed, deployed). Existing Voyager session ses_ebabda49affeLotdkpUHrOc86H PID 11800.)

- 2026-11-14T18:11:27Z Voyager: progress 40% (HEAD 7ece6206e34f91febb335477760c5f89e2ab2e7f (work/wormhole-manager-w0-017, pushed, deployed). Existing Voyager session ses_ebabda49affeLotdkpUHrOc86H PID 11800. Traced outbound: comms.Tell -> postAs -> resolveTarget (remote for pegasus) -> publishRemote -> wormhole.PublishRemoteMessage -> sp.Publish writes mail/<target>/new/<id>.md + commits+pushes. Traced inbound: spool.importLocked -> bus.PostExternal(source=fleet-comms, externalID=<wormhole-id>, from=<ChatGPT>, target=Voyager) -> publishExternalRecipientLocked writes <Voyager>/unseen/<CommsID>.json with ExternalSource=fleet-comms, ExternalID=<wormhole-id>, ExternalHash=<sha>. Plugin inbox poll injects via promptAsync. Reply correlation via ExternalID = original wormhole message ID. No local Comms record created for outbound remote messages (postAs returns early after publishRemote for remote targets), so no durable local record of 'Voyager sent wormhole msg W0-xxx to ChatGPT' exists for correlation.)
