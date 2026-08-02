Title: "Starfleet ↔ Telegram integration — design plan"
Category: parked
Status: "planning"
Assigned-To: "Saratoga"
Tags: "starfleet"
Slug: starfleet-telegram-integration-send-receive-telegram-message

## Design Plan (Praetor decisions 2026-07-29)

### Architecture

```
Telegram User ←→ Telegram Bot API ←→ starfleetctl bridge telegram ←→ comms bus
                                              │
                                    .starfleet-ai/conf/telegram.yaml
                                    TELEGRAM_BOT_TOKEN (env override)
```

The bridge is a new `starfleetctl bridge telegram` subcommand (package
`internal/bridge/telegram/`) that runs as a long-lived daemon process. It
uses the Telegram Bot API via long-polling (`getUpdates`) — no webhook
needed, no public IP required.

It appears on the comms bus as a ship, using the same in-process `comms.Bus`
API as the web server and bridged daemon already do.

### Praetor decisions

| # | Question | Decision |
|---|----------|----------|
| 1 | Bot token source | Both: `TELEGRAM_BOT_TOKEN` env var AND `.starfleet-ai/conf/telegram.yaml` (env wins) |
| 2 | Direction | Bidirectional (comms → Telegram push + Telegram → comms tell) |
| 3 | Self-hosted conflict | Clarify hosting model first — see below |
| 4 | Chat/user mapping | Single-instance mode: one Telegram chat/user = "Starbase" on the bus |
| 5 | Ship identity | Either dedicated name (like "McKinley") or Telegram usernames if multiple users, with clean disambiguation from real ships |

### Hosting model (to be clarified)

The bridge must run as a persistent daemon — unlike agent ships which are
per-session, the Telegram bridge must stay online to receive updates.

Options:

A) **Same host as web server** — `starfleetctl web` already runs as a
   persistent daemon; the Telegram bridge could be started alongside it
   (as another subprocess or in-process goroutine). Simplest, but ties
   Telegram uptime to the web server's.

B) **Separate daemon** — `starfleetctl bridge telegram start|stop|restart`
   with its own PID file + log, managed like the web server or timer
   worker. Independent lifecycle.

C) **In-process goroutine in the web server** — the web server already
   embeds comms + dashboard in-process; adding Telegram there means no
   extra process. But the web server needs to be running for Telegram to
   work.

D) **CI runner or cron** — polling-based, short-lived. Least suitable for
   bidirectional (would miss incoming messages between runs).

**Recommendation:** Start with (B) — independent daemon, same pattern as
`starfleetctl web start|stop`. Can later integrate into web server (C) if
desired, or run as subprocess of web server autostart.

### Data flow

#### Telegram → comms (inbound)

```
Telegram message → Bot API (getUpdates) → bridge parses chat+text
  → bus.Tell("Starbase", "<user>: <text>") or
    bus.Tell("<ship>", "<text>") if command syntax
  → ship processes via normal comms inbox
```

- If single-user mode: all messages become tells to "Starbase" ship
- The bridge acks processed updates so they're not re-fetched
- TODO: command syntax (e.g. `/tell Shipname message`) for directing

#### comms → Telegram (outbound)

```
New message in bus inbox for "Starbase" (or broadcast) →
  bridge polls inbox (like comms-watch) →
  via Bot API sendMessage(chat_id, text)
```

- Broadcasts go to all configured Telegram chats/users
- Direct tells to "Starbase" go to the primary chat
- Formatting: prefix with `[<from>] <text>` so Telegram user sees sender

### Configuration (`telegram.yaml`)

```yaml
telegram:
  # Bot token — override via TELEGRAM_BOT_TOKEN env var
  bot_token: ""

  # Poll interval for getUpdates (seconds, default 2)
  poll_interval: 2

  # Ship identity on the comms bus
  ship_id: "Starbase"
  ship_handle: "Telegram Bridge"

  # Chat configuration for single-user mode
  chat_id: 0                    # single primary chat (0 = disabled)
  # Future: multi-chat support via chat map

  # Outbound notification settings
  notify_broadcasts: true       # forward broadcasts to Telegram
  notify_tells: true            # forward tells addressed to our ship_id
  notify_board: false           # forward ship join/leave events
```

### Files to create/modify

| File | Action |
|------|--------|
| `internal/bridge/telegram/telegram.go` | New — core bridge: bot API client, polling loop |
| `internal/bridge/telegram/config.go` | New — telegram.yaml config loading |
| `internal/bridge/telegram/run.go` | New — `bridge telegram` subcommand dispatch |
| `internal/bridge/telegram/outbound.go` | New — comms → Telegram notification forwarding |
| `internal/bridge/telegram/inbound.go` | New — Telegram → comms tell injection |
| `internal/config/config.go` | Extend — add TelegramConfig struct |
| `cmd/starfleetctl/main.go` | Extend — add `bridge telegram` CLI route |
| `.starfleet-ai/conf/telegram.yaml` | New — default config (ship_id: Starbase) |

### Go dependencies to add

- `github.com/go-telegram/bot` or equivalent Telegram Bot API client
- Or implement the Bot API directly (it's just REST/JSON — few endpoints needed)

### Open questions for next session

1. Hosting model: which option? (A/B/C/D — recommendation B)
2. Command syntax for directing messages to specific ships from Telegram
   (e.g. `/tell Reliant status?`)
3. Multi-user support needed now or later?
4. Should the Starbase ship auto-ack incoming Telegram messages?
