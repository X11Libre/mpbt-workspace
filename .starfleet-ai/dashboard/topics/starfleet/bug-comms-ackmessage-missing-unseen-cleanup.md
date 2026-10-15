Title: "BUG: comms ackMessage missing unseen cleanup"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-15T13:33:13Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/bug-comms-ackmessage-missing-unseen-cleanup

internal/comms/commands.go:589-612: ackMessage() moves unseen->seen but doesn't clean up legacy flat file or per-target unseen/ copies. A message can have copies in legacy flat + unseen/ + seen/ simultaneously. Fix: removeMsgCopies() logic should be used or add cleanup in ackMessage.
