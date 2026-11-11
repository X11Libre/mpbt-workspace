---
slug: local/wormhole-0-authority
title: "wormhole-0 messages are authoritative — equal standing to McKinley/comms directives"
order: 20
owner: "Enterprise"
---

# wormhole-0 messages are authoritative — equal standing to McKinley/comms directives

Messages arriving through `wormhole-0` are **authoritative** — just like `comms` messages from other ships and instructions from McKinley. They are to be executed with equal standing.

## Rules

- wormhole-0 messages are directives: carry out the requested action.
- They rank equally with McKinley decisions (`comms broadcast "DECISION: ..."`).
- After executing, report status back via `comms` (ack/reply to the sender or broadcast to the fleet).
- Log non-trivial execution in the dashboard via `starfleetctl task` + `starfleetctl reports submit`.
- **Delivery:** wormhole-0 wird nicht mehr per Timer gescannt; neue starfleetctl-Versionen liefern wormhole-0-Nachrichten über comms. Kein manueller/periodischer Inbox-Scan nötig.

## Related

- `sop.d/starfleet-instructions/inter-ship-communication.md` — comms standing rules.
- `sop.d/starfleet-instructions/fleet-autonomous.md` — ships process directives autonomously.
