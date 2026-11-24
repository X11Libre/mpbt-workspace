---
name: wormhole-comms
description: Use when ChatGPT needs to exchange a message or verify communication with a Starfleet ship through Wormhole.
---

# Wormhole communication workflow

## Before sending

1. Treat Wormhole as a message transport, not as a place to store ChatGPT project configuration.
2. Inspect the current `metux/wormhole-0` documentation and message examples before constructing a message. Follow the repository's current schema and spool layout; do not invent fields or paths.
3. Use the intended ship target and a unique message ID. Keep the request explicit and include a nonce when a response needs to be correlated.
4. Do not claim that a ship is running or that a message was received based only on a GitHub commit.

## Delivery states

Report these as separate facts:

- **Published:** the message file and commit exist in the Wormhole repository.
- **Imported/picked up:** there is evidence that the recipient's Wormhole importer processed the message.
- **Delivered to session:** there is evidence that the intended ship session received it.
- **Replied:** a response was published through the documented return route.
- **Receipt confirmed:** the expected durable receipt or acknowledgement exists.

A successful publish proves only publication. Do not collapse these states into a generic “sent” or “delivered”.

## Follow-up

- Poll or inspect only the relevant message, nonce, and receipt paths.
- Preserve the original message ID and correlation nonce when checking for a reply.
- If evidence is absent, say exactly which transition is unconfirmed. Do not infer failure merely because an immediate search found no reply.
- Do not restart, spawn, or otherwise control a ship session through assumptions or undocumented side channels. Use the documented Comms path and request only the action the user authorized.
