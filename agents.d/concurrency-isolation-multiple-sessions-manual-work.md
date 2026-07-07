---
slug: concurrency-isolation-multiple-sessions-manual-work
title: "Concurrency / isolation (multiple sessions + manual work)"
order: 160
---

## Concurrency / isolation (multiple sessions + manual work)

**The unit of isolation is the clone (working tree + index), not the repo.** All safety rules
follow from that.

- **Safe by construction:** different release clones (`_WORK_/xserver-<rel>/…`) are separate
  working trees, so a session in one release and work in another cannot clobber each other's
  files/index/HEAD. They share only the GitHub remote, and pushes go to distinct
  `rfc/backport-<rel>` branches. **Parallelize across releases freely.**
- **The hazard:** two actors (two sessions, or a session + manual edits) mutating the **same**
  clone at once. Git has no native working-tree lock — concurrent `checkout` / `add` / `commit`
  / `rebase` will silently corrupt each other's state.
- **`scripts/xx-make-pr.sh` needs exclusive access to its clone for its whole runtime.** It
  fetches, creates/renames/deletes branches, switches branches, and **rewrites the incubator
  branch history**. Never run anything else in that clone while it runs.

### Two agents on the same PR — claim it first (`scripts/pr-claim`)

Separate clones isolate *files*, but every clone pushes to the **same GitHub PR branch**. So two
agents repairing the **same PR** in two clones is still a conflict: their `pr-amend-push`
force-pushes clobber each other (last writer wins, the other's fix is silently lost) and they post
duplicate review comments. Clone isolation does **not** cover this; PR-branch ownership does.

**Protocol — before you start mutating a PR (repair, amend, backport-to-a-PR):**

```bash
export AGENT_ID=<short-unique-name>      # e.g. repair-3132 — distinguishes concurrent agents
scripts/pr-claim <pr#> "what you're doing"   # exit 3 => another agent holds it: pick another / coordinate
# ... pr-checkout / edit / pr-amend-push ...
scripts/pr-claim --release <pr#>         # when done (or --release-all at session end)
```

- `scripts/pr-claim --list` is the **shared work log** — "which agent is on which PR right now."
- Advisory, like `with-clone-lock`: it only guards actors that also call it. `pr-checkout` does a
  soft `--who` check and **warns** (doesn't block) if the PR is already claimed.
- Claims are keyed by PR#, `flock`-serialized, stored gitignored under `_WORK_/agent-claims/`
  (with an `events.log` audit trail), and go **stale after `$CLAIM_TTL`** (default 1h) so an agent
  that exited without releasing doesn't wedge the PR — a stale claim is auto-reclaimed (logged);
  use `--steal <pr#>` to take over a still-fresh claim from an agent you know is gone.
- **Read-only review needs no claim** — only mutation (pushing to the branch) does.
- Pushing to **distinct** branches never conflicts, so across *different* PRs / release lines you
  still parallelize freely; the claim is only about the shared branch of one PR.

### Central control plane — one agent monitors/steers the others (`scripts/agent-bus`)

`pr-claim` coordinates *ownership of one PR branch*; `agent-bus` is the broader **control
plane** so a single control agent (a "1st officer") — or a future dashboard / voice UI / MCP bus —
can see what every independent session is doing and steer it, instead of switching between many
terminals. Same model as everything else here: no process talks to another directly; all parties
read/write the same gitignored files (`_WORK_/agent-bus/`, `flock`-serialized), so it works across
**totally independent** `claude` (or human) sessions, not just spawned subagents. Pull-based and
advisory — workers must poll their `inbox`; nothing forces a session to act.

- **Worker session** (one per release line / task): set a unique `$AGENT_ID`, then
  `agent-bus status <state> ["note"]` to report/refresh a heartbeat (states are free text:
  `working|building|reviewing|blocked|idle|done`); `$XLIBRE_RELEASE` auto-fills the project column.
  Check `agent-bus inbox` for directives addressed to you or to all, and `agent-bus ack <id>` when
  handled. `agent-bus clear` on exit.
- **Control agent** (`AGENT_ID=Enterprise` — the flagship): `agent-bus board` (the default no-arg
  command) is the whole-fleet view — every agent, project, state, heartbeat age, unacked-inbox
  count, note, `[STALE]` past `$BUS_TTL` (15m). Steer with `agent-bus tell <agent> <text…>` (one
  agent) or `agent-bus broadcast <text…>` (all); `agent-bus msgs` shows directives + ack counts,
  `agent-bus events` the audit trail, `agent-bus prune` reaps stale heartbeats + fully-acked old
  directives.

**Heartbeats are auto-reported — both session types register on the `board` without a manual call:**
- **Claude Code** via checked-in `.claude/settings.json` hooks: `SessionStart`
  (`agent-bus status idle "session started"`) and `SessionEnd` (`agent-bus clear`), invoked as
  `"$CLAUDE_PROJECT_DIR"/scripts/agent-bus …` (cwd-independent, `… || true` so they never block a
  session). `SessionStart` also launches **`scripts/agent-bus-watch`** (detached) and `SessionEnd`
  stops it (`--stop`): a local, LLM-free poller that **notifies** (append to
  `_WORK_/agent-bus/notify/<agent>.log` + best-effort `notify-send`) when a new directive for this
  agent (or `all`) arrives. Notify-only for now — it does not act on/ack directives; it runs only
  while a client session is open, so it costs nothing (no API) until mail actually lands.
- **opencode** via the `run-opencode.xserver-*` wrappers: each exports a per-session
  `AGENT_ID=${XLIBRE_RELEASE#xserver-}-$$` (release + PID, unless already set) and runs
  `agent-bus status idle "opencode session"` just before `exec opencode`. opencode does **not** fire
  Claude Code's hooks, so there's no auto-`clear` on exit (`exec` also rules out a cleanup `trap`) —
  the heartbeat is reaped by the `$BUS_TTL` staleness (15m) / `agent-bus prune`.

Agents still call `agent-bus status <state>` to report *what* they're doing as it changes; the
auto-heartbeat only registers presence. **Caveat:** the Claude Code hook inherits the session's env
and identity falls back to `user@host` when `$AGENT_ID` is unset — so for a plain `claude` session
(not launched via a wrapper) **export a unique `$AGENT_ID`** (and `$XLIBRE_RELEASE` for the project
column) first, or all same-host sessions collapse to one board row and a `SessionEnd` in any one
clears it for all. (The `run-opencode.*` wrappers already set both.)

**Don't prefix `export AGENT_ID=... &&` in front of `scripts/agent-bus`/`scripts/pr-claim` calls
when `$AGENT_ID` is already in the session's environment** (true for every launcher/hook-started
session in this workspace — the whole point of the ship-name/auto-id machinery above). Doing it
anyway is harmless functionally but breaks the `Bash(scripts/agent-bus *)`/`Bash(scripts/pr-claim
*)` allowlist entries, which match on the command line's literal *prefix*: `export AGENT_ID=Foo &&
scripts/agent-bus board` does not start with `scripts/agent-bus`, so it prompts for confirmation
even though a bare `scripts/agent-bus board` would not have. Only export/override `$AGENT_ID`
inline when you deliberately need a *different* identity than the session's own for one call.

**The same prefix-matching gotcha bites *any* chained command, not just `export AGENT_ID=...
&&`.** Allowlist entries like `Bash(gh)`/`Bash(gh *)` only match when the command line *itself*
starts with `gh` — `echo "AGENT_ID=$AGENT_ID"; gh pr view <n> --json ... -q '{...}'` starts with
`echo`, so it prompts for confirmation even though `gh` alone is allowlisted (hit on Pegasus,
2026-07-03, checking identity + PR #3226 status in one shot). Split unrelated diagnostics
(`echo`/`export`/a status print) and the allowlisted command into **separate Bash tool calls**
instead of chaining with `;`/`&&`/`|`. For the specific "print PR metadata" case, use
`scripts/pr-view <pr#> [fields]` (one canonical allowlisted command) rather than hand-rolling
`gh pr view --json ...`.

**Ship names for fleet identity (2026-07-03).** Every agent instance — whether a plain `claude`
session, an `agent-run`-launched tmux session, or the flagship `run-flagship` — gets a unique **Star
Trek ship name** as its `AGENT_ID`. `Enterprise` is reserved for the flagship/control session; worker
sessions are assigned the next free name from `scripts/ship-names.txt` (50 ships, Federation /
Klingon / Romulan / Cardassian / Bajoran) via `scripts/ship-names assign`. Names are visible:
- **Shell prompt:** `agent-bus-auto-id.sh` prefixes `(Defiant) ` to `$PS1` on first entry.
- **Claude Code status line:** `⚓ Defiant` rendered by the `statusLine` hook in `.claude/settings.json`.
- **tmux:** session is named `mpbt-Defiant`, visible in `tmux ls` and on the `agent-bus board`.
- **Agent bus board:** ship name IS the `AGENT_ID` column — reads like a fleet roster.
Names are released automatically: by `EXIT` trap / zsh `zshexit` in `agent-bus-auto-id.sh`, by
`agent-run --stop`, and by the Claude Code `SessionEnd` hook. Stale reservations can be cleared
with `scripts/ship-names gc`.

**Fixed for plain `claude` sessions via a dotfile-sourced auto-ID script (2026-07-02, updated 2026-07-03):**
`scripts/agent-bus-auto-id.sh` auto-assigns a ship name as `AGENT_ID` whenever an
interactive shell's `$PWD` is inside this workspace tree and `$AGENT_ID` isn't already set (so it
composes with the `run-opencode.*` wrappers and `run-flagship` rather than overriding them). It must be **sourced from
the user's `~/.bashrc`/`~/.zshrc`** (one line: `[ -f
/home/nekrad/src/xorg/mpbt-workspace/scripts/agent-bus-auto-id.sh ] && . <that path>`), *not* wired
as a Claude Code hook — checked against the hooks JSON schema: `SessionStart`/`SessionEnd` hooks run
as one-shot child processes and have no output field that injects env vars back into the
interactive session's shell (only `systemMessage`/`decision`/`hookSpecificOutput.additionalContext`
etc). `$AGENT_ID` must already be in the environment *before* `claude` starts so it propagates via
ordinary process-env inheritance into both the existing `SessionStart`/`SessionEnd` hook commands
and every Bash-tool-backed shell of that session — no `settings.json` change was needed once the
env var is populated upstream of the client process.

**Cross-repo agents can join this board too, by the praetor's direction.** `agent-bus`/
`DASHBOARD.md` aren't limited to sessions rooted in this checkout — an agent working in a
*sibling* repo the praetor also maintains (e.g. **`go-x11proto`** — the Go X11-protocol client
library the `go-xts` CI suite is built on, see "go-x11proto pin sites" above) can register on this
same board when told to, with its `$XLIBRE_RELEASE`/project column simply naming that other repo.
(As of 2026-07-02 go-x11proto is itself an mpbt solution — see "go-x11proto is its own mpbt
solution" below — so its clone now lives *inside* `_WORK_/go-x11proto/sources/xlibre/go-x11proto`,
not at the old external `/home/nekrad/src/xorg/go-x11` path.) Treat such an
entry as legitimate coordination, not stray noise — the praetor explicitly wires up
cross-project agents this way when their work affects xserver CI (e.g. a go-x11proto version bump
needed here). Same rule applies to `DASHBOARD.md`: a cross-repo theme is fine there if it has a
concrete effect on this workspace's build/CI/tests.

**Auto-surfacing directives via `Monitor` (Claude Code only, 2026-07-03).** `agent-bus-watch` is
notify-only — it tells a human via desktop popup, but a live session doesn't see the directive
unless it happens to run `agent-bus inbox` itself. Claude Code's **`Monitor` tool** closes that gap
*without* crossing into unsupervised auto-execution: it's a background poll loop whose stdout lines
land as real events *inside* the session's own conversation (the same mechanism used to watch a
background build or a CI run), so a new `tell`/`broadcast` appears to the assistant like any other
observed event — the assistant still reasons about it and goes through the normal tool-permission
flow for whatever it decides to do. That's a meaningfully smaller blast radius than the alternative
that was considered and rejected (`tmux send-keys` injection into an `agent-run` pane) — no raw
keystroke injection bypassing confirmations, and it works uniformly for both foreground and
`agent-run`/tmux-launched sessions since it's a session-level tool, not tied to the tmux backend.

**Command: `scripts/agent-bus-monitor-loop`** (2026-07-03, replacing an earlier inline heredoc —
see below for why). Call `Monitor` with `command: "scripts/agent-bus-monitor-loop"`,
`persistent: true`. The script reads `$AGENT_ID` from the environment (already exported by every
launcher/hook in this workspace) and keeps its dedup state under
`_WORK_/agent-bus/monitor-seen/<AGENT_ID>` — so, unlike the old approach, **the invocation is the
exact same string for every session**. That matters for permissions: `.claude/settings.json` now
carries a bare `"Monitor"` allow entry, so this call needs **no confirmation prompt** at all,
in any session. (The bare-tool-name form — no `(...)` — allows every invocation of that tool
regardless of arguments, same as a bare `"Read"` entry; be aware this is a blanket grant, not
scoped to this one script, consistent with the other standing `scripts/*` grants already in this
file for this same trust boundary.) The script's first loop pass already scans all existing
messages, so arming it also serves as the one-time backlog check — no separate `agent-bus inbox`
call needed.

**Unconditional as of 2026-07-03** (was initially a discretionary nudge — changed after observing
several fleet sessions sitting idle with an unarmed inbox and unacked directives):
`scripts/agent-bus-monitor-hint` runs as a third `SessionStart` hook command and emits a
`hookSpecificOutput.additionalContext` instructing the assistant to arm this **as its very first
action, every session, no judgment call** — not "if it'll stick around." First real-world
validation (2026-07-03, the `Enterprise`/control session): arming the Monitor immediately surfaced
a 3-message backlog including an "ASAP" backport request (`m0011`) that had been sitting unclaimed
with no live session polling for it — concretely proving the gap this closes. Turned out already
superseded (PR #3226's backports were already open before the directive was even read) — a
reminder that `agent-bus` mail can go stale exactly like the board itself; ack with an explanation
instead of blindly acting when that happens.

**Why the command moved out of an inline heredoc into `scripts/agent-bus-monitor-loop`.** The
original approach had the hint dictate a self-contained bash snippet embedding `$AGENT_ID` and a
session-scratchpad path directly in the `Monitor` call's `command` argument. That worked, but every
session produced a *different* command string (different agent, different scratchpad path), so it
could never be permission-allowlisted — every arming, plus the `agent-bus inbox`/`agent-bus status
idle` calls the old hint also asked for, prompted for confirmation individually (reported
2026-07-03: "funktioniert schonmal - emittiert allerdings noch eine menge kommandos, die extra
bestätigt werden müssen"). Moving the loop into a script with no session-specific parameters (env
var instead of an interpolated literal, a fixed workspace-relative seen-dir instead of the
scratchpad) turned it into one static, allowlistable invocation — and made the explicit inbox-check
step redundant, since the script's own first pass covers it.

**Hard limit: a hook can't invoke a tool — this only fires on the session's first turn.** A `claude`
process that has been launched (heartbeat posted, shows up on `agent-bus board` as `idle`/"session
started") but has not yet received any input has had **no turn** yet, and `Monitor` can only be
called by the assistant during a turn — so its inbox stays genuinely unwatched until the first
message arrives. This is why a broadcast could sit un-acked at freshly-started ships
(`Discovery`/`Excelsior`/`Voyager`, seen 2026-07-03) even with the hint wired up: they simply hadn't
taken a turn yet, not that the hint failed.

**Closed the remaining gap by having the launcher supply that first message itself
(`scripts/agent-bus-boot-prompt`, 2026-07-03).** A session still can't self-trigger a tool call with
zero interaction — but the *launcher* isn't a session, it's a plain shell script that controls what
gets fed to `claude` as its initial argument, and `claude [prompt]` (no `-p`) starts interactively
with that prompt already submitted as the first turn. So `run-ship`, `run-flagship`, and
`agent-run --client claude` now each check: if the caller gave no explicit initial prompt/args, feed
`scripts/agent-bus-boot-prompt`'s text (arm the Monitor via `scripts/agent-bus-monitor-loop`, then
wait) as the initial `claude` argument instead of leaving it empty. This forces the first turn —
and with it the Monitor-arming — at launch time, with nobody needing to type anything.
Skipped whenever the caller *does* pass their own initial args/prompt (respects explicit intent,
never overrides it). `run-flagship --detach` composes cleanly: it fills `EXTRA` with the boot prompt
itself before delegating to `agent-run`, so `agent-run`'s own empty-check no-ops instead of
double-injecting. The prompt text itself shrank once the Monitor call became the *only* required
first action (see above) — arming `scripts/agent-bus-monitor-loop` and then waiting, no more
separate inbox-check/status-report steps spelled out (status is already handled by the existing
`SessionStart` heartbeat hook, which runs outside the permission system entirely since it's not a
model-invoked tool call).

**Flagship also needs the fleet-membership watch, not just its own inbox (2026-07-03).** The
`agent-bus-fleet-watch` script (see Key commands) existed but wasn't wired into the auto-arm path
above — a freshly (re)launched `Enterprise` session only armed `agent-bus-monitor-loop`, so a ship
restarting (e.g. Potemkin) produced no in-context notification even though the control session was
supposed to be watching the whole board. Fixed by making `agent-bus-boot-prompt` and
`agent-bus-monitor-hint` both branch on `$AGENT_ID`: for `Enterprise` they now instruct arming
**both** Monitors (`agent-bus-monitor-loop` + `agent-bus-fleet-watch`); every other identity still
gets just the inbox watch, since fleet membership is only the flagship's concern. One wrinkle in
`agent-run`: at the point it calls `agent-bus-boot-prompt` internally (for a bare `agent-run
<release> --client claude --name Enterprise`, i.e. not via `run-flagship`), `AGENT_ID` is still only
a local shell variable, not yet exported into the environment (that happens later, in the string
built for the inner tmux command) — so the branch would silently miss it. Fixed by passing it
explicitly: `AGENT_ID="$AGENT_ID" "$ROOT/scripts/agent-bus-boot-prompt"`, mirroring the same
inline-env-var pattern the script already uses for the actual `exec` line.

**Gap: opencode has no equivalent.** `Monitor` is a Claude Code harness tool; opencode sessions have
no comparable in-context event mechanism, so they're stuck on notify-only (desktop popup) for now.
Parked in `DASHBOARD.md` as a follow-up (give opencode *some* notify capability, even if not full
in-context surfacing).

**Roadmap:** the file layout is deliberately the data layer a richer controller can sit on
unchanged. Two steps exist now — `scripts/agent-bus-watch` (desktop notify, per-session via the
hooks above) and the `Monitor`-based in-context surfacing above. Still open: a TUI dashboard tailing
`status/` + `msgs/`, true auto-*execution* of directives (something other than the assistant's own
judgment triggers the action — not attempted; the `Monitor` approach deliberately keeps a human-grade
reasoning step in between), an opencode-side notify story, and an **MCP server in HTTP/SSE mode**
(runs as a daemon, serves many independent sessions at once, needs no Claude key, carries its own
creds for any external access) acting as a push message-bus instead of file polling. Start with the
files; promote to MCP when polling latency or multi-host reach demands it.

### Detaching sessions + multi-controller access (`agent-run` / `agent-attach`, tmux)

Goal: run agents detached from any terminal, and let an **arbitrary number of controller clients each
reach every running agent** — fully self-hosted, no cloud, any CLI. The backend is **tmux**: the
tmux server is a daemon, so a session survives terminal close / SSH disconnect, and multiple
`tmux attach` to one session = multiple controllers driving the *same* live agent.

- **Launch detached:** `scripts/agent-run <release> [--client claude|opencode|shell] [--name <id>] [-- <args>]`.
  Starts the client in a `tmux` session named `mpbt-<AGENT_ID>`, exports `AGENT_ID` + `XLIBRE_RELEASE`
  + `AGENT_HANDLE` (= the tmux session) into it, and writes an initial heartbeat — so it appears on
  `agent-bus board` with its ATTACH handle immediately. `--list` shows running sessions + board;
  `--stop <id>` kills one.
- **Attach a controller:** `scripts/agent-attach <id>` (resolves `<id>` via the board / tmux names).
  Run it from any terminal on the host (or over SSH) — as many as you like, concurrently.
  `--read-only` watches without typing; `--independent` gives that controller its own window size
  (a grouped session) instead of the shared-size default. `Ctrl-b d` detaches; the agent keeps running.
- **Reach from another machine:** SSH into the host and run `agent-attach` there — tmux needs no
  network service of its own. (For N remote controllers that's N SSH logins to the one host where
  the agents run.)

**Prereqs / caveats:**
- **`tmux` must be installed** (`sudo apt install tmux`) — `agent-run`/`agent-attach` refuse with a
  hint otherwise. It is the only added dependency.
- Survives terminal close + SSH disconnect out of the box. To also survive a full **logout**
  reliably, enable lingering once: `loginctl enable-linger "$USER"`. It does **not** survive reboot
  (agents are in-flight conversations — just relaunch).
- `agent-attach` execs `tmux attach`, which needs a real TTY — it's a human/controller command, not
  something the agent tool itself runs (it errors when stdout isn't a terminal).
- **Why not Claude Code's native Remote Control / agent-view?** Remote Control routes through
  Anthropic's cloud (no self-hosted bridge) and only covers Claude Code sessions, not opencode — so
  it fails the "self-hosted + every client" requirement. The background agent-view supervisor is
  also Claude-only and same-host. tmux is the CLI-agnostic, self-hostable, multi-attach equivalent.

### Fleet auto-scaling and the two-tier permission model (`fleet-autoscale`)

**Standing policy, confirmed directly by the maintainer 2026-07-06 (agent-bus m0037/m0038/m0051/
m0066/m0068) — full implementation history in DASHBOARD.md's "Fleet auto-scaling" row.** When more
parallelizable work is queued than there is idle fleet capacity, `scripts/fleet-autoscale need <N>
--reason "<text>"` spawns extra ships on demand (via `ship-names assign` + `agent-run`) — an
**explicit, on-demand trigger only**, never a background daemon/cron/Monitor-loop; see the Key
commands table entry and the script's own header for the demand-signal/hard-cap/audit-trail design.

Ships it spawns are a distinct, lower **tier** from a normal interactively-launched session:

- **Upper tier — anyone started directly at a terminal** (a human typing `run-ship`/`run-flagship`,
  or a control ship like `Enterprise`): ordinary interactive permission confirmation, because a
  human is actually there to answer prompts. Completely unaffected by anything below.
- **Lower tier — `fleet-autoscale`-spawned workers**: tagged `AGENT_TIER=worker` +
  `AGENT_SUPERVISOR=<name>` (default `Enterprise`; **no** per-ship ownership/reassignment
  tracking — any control ship may address any free worker ship, by deliberate simplification) and,
  for `--client claude`, launched with **`claude --permission-mode dontAsk`** — NOT
  `--dangerously-skip-permissions` — so anything outside `permissions.allow` is rejected outright
  instead of blocking on a confirmation nobody is watching. `scripts/agent-bus-boot-prompt`'s
  worker-tier branch instructs such a ship that on a rejected/blocked action it must not keep
  retrying or silently give up, but `agent-bus tell $AGENT_SUPERVISOR` exactly what it tried and
  why, then continue other queued work or wait for a reply — the supervisor (human or control ship)
  can grant it interactively, which the worker itself cannot.

**Why this needed explicit sign-off, not just a bus directive:** lowering the confirmation floor for
unattended agents is a materially bigger, harder-to-reverse safety change than routine fleet
coordination — arriving via an unauthenticated `agent-bus` relay (see the "agent-bus has no message
authentication" Parkplatz entry) is not sufficient on its own for a change in this class. It was
asked for directly, twice, in the implementing agent's own session before being built. **The
maintainer's follow-up calibration**: this specific, now-approved category (further tuning of the
dontAsk/worker-tier mechanism itself) does **not** need a fresh direct round-trip each time —
indirect confirmation relayed via the flagship is sufficient going forward for it. A genuinely
*new* category of permission-loosening or other higher-impact change still warrants asking
directly again, the same way this one originally did.

**Preferred: agents work in their own dedicated clones.** Agents/automation must NOT do backport
work in the user's hand-edited `sources/xlibre/xserver` clone. Instead create an agent-owned clone:

```bash
scripts/starfleetctl mk-agent-clone <release> [name]   # e.g. mk-agent-clone 25.2
# -> _WORK_/xserver-<rel>/agent/<name>/xserver   (gitignored)
```

- **Full isolation, cheap.** origin = GitHub, but the object store is borrowed from the user's
  clone via git **alternates** (`--reference-if-able`, degrading to a normal full clone if the
  reference is shallow), so the new `.git` is a few hundred KB, not a full
  copy. Refs, index, HEAD and config are independent.
- **Reproduces the mpbt repo config.** mpbt configures the source clones with settings
  `xx-make-pr.sh` and the remotes depend on (the `make-pr.*` keys, plus `remote.origin` tagopt /
  namespaced tag refspec and the `xorg` upstream remote). `mk-agent-clone` copies the entire
  `make-pr.*` and `remote.*` config sections verbatim from the reference clone — so it tracks any
  future keys automatically rather than hard-coding a subset. Re-running it is idempotent and
  repairs config drift.
- **This is why a clone, not a worktree:** `xx-make-pr.sh` *rewrites* the `rfc/backport-<rel>`
  branch history. A worktree shares the ref store, so that rewrite would mutate the user's branch.
  A separate clone shares only objects, so it can't. The agent clone tracks
  `origin/rfc/backport-<rel>` (the shared incubator) and pushes PRs to the real GitHub remote.
- **Multiple parallel agents:** give each its own `name` (`mk-agent-clone 25.2 alice`).
- **Object-sharing caveat:** the agent clone borrows objects from the user's clone, so do **not**
  run `git gc --prune` / aggressive `git repack` in the user's `sources/…` clone while agent
  clones reference it — that can prune objects the agent clone needs. To detach a clone from the
  shared store, run `git repack -a -d && rm .git/objects/info/alternates` (or clone with
  `--dissociate`) — costs disk but removes the coupling.

**Fallbacks when not using a dedicated clone:**

- **Per-task git worktrees** — own working dir + index + HEAD, shares the object store. Git
  refuses to check out the same branch in two worktrees (a useful guard). But note the ref-store
  caveat above: don't run history-rewriting tools like `xx-make-pr.sh` from a worktree of a clone
  someone else uses. (Claude Code can spawn agents with `isolation: "worktree"`.) **`scripts/worktree
  add <repo> [name]`** wraps the create/list/remove/prune lifecycle for exactly this case, for
  any repo — see the Key commands table — and is pre-authorized so it needs no confirmation.
- **`scripts/with-clone-lock`** — advisory per-working-tree `flock`; wrap mutating commands so
  cooperating actors serialize instead of colliding:
  ```bash
  scripts/with-clone-lock scripts/xx-make-pr.sh <commit-sha>
  scripts/with-clone-lock                       # subshell; lock held until exit
  ```
  Keyed to the per-worktree git dir (separate worktrees/clones run in parallel; same tree
  serializes). Auto-releases on process exit. **Advisory only** — guards against actors that also
  use the wrapper, not raw edits. Records holder in `<gitdir>/mpbt-clone.lock`; `LOCK_WAIT`
  (seconds, default 600) sets the timeout.

**Rule of thumb:** agents → own clone via `mk-agent-clone`; parallelize freely *across* releases;
*within* a release use a per-agent clone name (or worktree / `with-clone-lock`). Always run
`xx-make-pr.sh` from an isolated tree.
