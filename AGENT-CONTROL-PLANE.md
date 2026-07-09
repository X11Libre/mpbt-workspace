# Agent control plane — the "1st officer" model

Goal: the maintainer talks to **one** central agent (the *control agent* / "1st
officer") instead of servicing every parallel worker. Workers route their
**questions** — and, later, their **tool-permission prompts** — to the control
agent, who asks the human once and routes the answer back. Built on `agent-bus`
(file-based, advisory); no new daemon, no API cost while idle.

## Quickstart (for you, the maintainer)

**Be the 1st officer.** In the one session you want to man, start it as the
controller and watch the board:

    export AGENT_ID=control          # this session is the controller
    scripts/agent-bus board          # who's online, who has unanswered mail
    scripts/agent-bus asks           # questions waiting for you

When a worker asks something you'll see a desktop notification (from the notify
watcher) and it shows up in `asks`. Answer it:

    scripts/agent-bus reply <qid> "your answer"        # free-form question
    scripts/agent-bus reply <qid> allow                # a [perm] request → allow
    scripts/agent-bus reply <qid> deny                 #                  → deny

**Steer workers** (unchanged): `scripts/agent-bus tell <agent> "…"` /
`broadcast "…"`.

**A worker asks you** (any session): `scripts/agent-bus ask "should I force-push?"`
— it blocks until you `reply`, then prints your answer.

**Route a worker's tool-approvals to you** (opt-in, per worker): add to *that
worker's* `.claude/settings.local.json`:

    "hooks": { "PreToolUse": [ { "matcher": "Bash",
      "hooks": [ { "type": "command", "timeout": 120,
        "command": "/home/nekrad/src/xorg/mpbt-workspace/scripts/agent-permission-hook" } ] } ] }

Then that worker's `Bash` permission prompts come to you as `[perm]` questions.
If you don't answer within the timeout it **denies** (fail-closed). Don't put
this in shared/committed settings — an absent controller would block everything.

**Turn it off:** stop being controller = just close/rename the `control` session
(pending questions time out → workers get the fail decision). Remove the
`PreToolUse` block to stop routing a worker's approvals.

## Roles

- **Control agent** — a human-attended session, `AGENT_ID=control` by convention
  (`$AGENT_CONTROLLER` overrides the target). Runs the notify watcher
  (`scripts/starfleetctl agent-bus watch`, see AGENTS.md) so new questions surface; answers the human
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

Because it's the existing directive channel, the controller's `scripts/starfleetctl agent-bus watch`
already notifies on incoming questions — no extra plumbing.

## Step 2 — tool-permission forwarding (BUILT, opt-in)

`scripts/agent-permission-hook` is a Claude Code **`PreToolUse` hook** that routes
a tool's permission decision to the controller instead of prompting the local
session. It reads the PreToolUse payload, `agent-bus ask`s the controller
`[perm] allow <tool>: <summary> — for <agent>?`, **blocks** for the answer, and
emits `permissionDecision` = `allow`/`deny`. The controller answers with
`agent-bus reply <qid> allow|deny`.

**Opt-in, per worker** — add a `PreToolUse` entry to a worker's
`.claude/settings.local.json` (never globally / in shared `settings.json`, or a
non-answering controller would gate every matched tool call):

```json
"hooks": { "PreToolUse": [ { "matcher": "Bash",
  "hooks": [ { "type": "command", "timeout": 120,
    "command": "/abs/path/scripts/agent-permission-hook" } ] } ] }
```

Fail-safe (verified against the hook contract): Claude Code's own hook timeout
**fails open** (the tool proceeds), so the hook enforces its **own shorter**
timeout and returns first:
- `$AGENT_PERM_TIMEOUT` (default 60s; keep it below the hook's `timeout`),
- `$AGENT_PERM_TIMEOUT_DECISION` = `deny` (default, fail-closed) | `ask`,
- `$AGENT_CONTROLLER` (default `control`).

Verified end-to-end (feeding a PreToolUse payload + a controller reply): allow→
allow, deny→deny, no-answer→deny. Note the precedence rule: a hook can't override
a `deny`/`ask` permission *rule* (most-restrictive wins), so it widens nothing —
it only answers what would otherwise be a prompt.

**Trust:** you approve *other* workers' commands centrally — the question shows
the agent id + the exact command, so you see what you're allowing.

## Roadmap

The bus files are the data layer; the robust long-term substrate is an **MCP
server (HTTP/SSE)** as a push message-bus (bidirectional, no polling, no Claude
key, serves many sessions) — see AGENTS.md "Roadmap". Start with the files;
promote to MCP when latency or multi-host reach demands it.
