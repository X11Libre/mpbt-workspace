# Known Limitations

## Comms Message Flow

Comms messages are delivered through the following pipeline:

```
Comms inbox
  → Message claim (ship-level, no Consumer-ID)
  → OpenCode promptAsync handoff
  → seen_mark
```

### Key Properties:

- **Wormhole is a Comms transport backend, not a parallel messaging system.**
  Received messages are imported only through `Bus.PostExternal`, and the agent/session plugin only ever reads the local Comms inbox.

- **`PostExternal` is the sole import boundary from Wormhole into Comms.**
  No other code path writes Comms records from the Wormhole perspective.

- **Comms Core remains the sole owner of local Comms data.**
  Only `Bus.PostExternal` writes `msgRecord` entries into `msgs/<ship>/unseen/`.

- **Messages are addressed to Ships, not Sessions.**
  Ship-level claims (not Consumer-IDs) determine which ship can claim a message.

- **Ship exclusivity is guaranteed by the instance manager.**
  The Dispatch plugin does not implement its own instance locking or lease mechanism.
  The separate Starfleetctl instance manager ensures at most one OpenCode instance per ship.

- **No `session.list()`-based Title-Matching and no `session.status()`-Fallback.**
  Session resolution is exclusively over reliable Lifecycle-Events (chat.params, session.created).

- **Claim must occur before Injection.**
  `claimMessage` must be called before any prompt injection.

- **ACK-Retry without erneute Injektion.**
  `seen_mark` is the idempotent counterpart to `ack`; repeated calls are no-ops.

- **Claim-Freigabe bei fehlgeschlagener Übergabe.**
  If the claim/prompt/seen sequence fails, the message claim is released and can be retried on the next poll cycle.

- **Neustart darf weder Nachrichten verlieren noch bereits übergebene Nachrichten duplizieren.**
  - `PostExternal` dedup via source+externalID+payload-SHA
  - Maildir Zustände: new→cur→processed, jeder Übergang ist eigenes Commit+Push
  - Message-Claim TTL (5 min) behandelt Prozessabstürze über Ablaufdatum

- **Großnachrichten (>= 50 KiB) müssen unverändert und vollständig übertragen werden.**
  - `PostExternal` nimmt ganzen Text (kein Truncieren)
  - Auto-Spill bei >768 Bytes hält Payload in Attachment, inline zeigt nur Fetch-Pointer

### Known Limitations (documented as-is):

- No support for `session.list()`-based title matching
- No support for `session.status()`-based session resolution
- No support for title-based session resolution
- Delivery guarantee remains at-least-once; a crash between Handoff and seen_mark may cause re-delivery
