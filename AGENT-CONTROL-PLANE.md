# Agent control plane — the "1st officer" model

Goal: the maintainer talks to **one** central agent (the *control agent* / "1st
officer") instead of servicing every parallel worker. Workers route their
**questions** — and, later, their **tool-permission prompts** — to the control
agent, who asks the human once and routes the answer back. Built on `agent-bus`
(file-based, advisory); no new daemon, no API cost while idle.

## Roles

- **Control agent** — a human-attended session, `AGENT_ID=control` by convention
  (`$AGENT_CONTROLLER` overrides the target). Runs the notify watcher
  (`agent-bus-watch`, see AGENTS.md) so new questions surface; answers the human
  (e.g. via the client's question UI) and replies on the bus.
- **Workers** — every other session (interactive, headless `claude -p`, or
  detached `agent-run` tmux). They `ask` the controller and block locally for the
  answer.

## Step 1 — question/answer channel (BUILT)

On the directive channel: a question is a directive to the controller tagged
`[ask]`; the answer a directive back to the asker tagged `[re <qid>]`.

- Worker: `agent-bus ask "<question>" [--to <ctrl>] [--timeout <secs>]`
  — posts the question, then **blocks on a local file-poll** (no API/LLM) until
  the reply lands, then prints the answer (exit 0) or times out (exit 3).
- Controller: `agent-bus asks` lists pending questions; `agent-bus reply <qid>
  "<answer>"` routes the answer back and acks the question.

Because it's the existing directive channel, the controller's `agent-bus-watch`
already notifies on incoming questions — no extra plumbing.

## Step 2 — tool-permission forwarding (PLANNED, on explicit request)

Route "allow command XYZ?" prompts to the controller instead of the local UI, via
a Claude Code **`PreToolUse` hook** on workers:

1. Hook intercepts the tool call, `agent-bus ask`s the controller "allow `<cmd>`
   for `<agent>`?" and **blocks** for the decision.
2. Returns allow/deny to Claude Code based on the reply — the worker's own
   session never prompts.

Caveats to handle when building:
- The tool call blocks on the human answer (same as a normal prompt, just
  centralised); many at once = a queue in the controller.
- **Timeout fallback:** if the controller doesn't answer, deny (or fall back to a
  local prompt) — never hang a worker forever.
- **Trust:** you are approving *other* workers' commands centrally — the prompt
  must show agent id + the exact command.
- Verify the exact `PreToolUse` allow/deny/ask contract before relying on it.

## Roadmap

The bus files are the data layer; the robust long-term substrate is an **MCP
server (HTTP/SSE)** as a push message-bus (bidirectional, no polling, no Claude
key, serves many sessions) — see AGENTS.md "Roadmap". Start with the files;
promote to MCP when latency or multi-host reach demands it.
