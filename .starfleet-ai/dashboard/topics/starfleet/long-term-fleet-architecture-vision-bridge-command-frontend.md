Title: "Long-term fleet architecture vision: bridge command frontend, multi-workspace federation, decentralized/isolated execution"
Category: parked
Status: "Vision from praetor 2026-07-06 — bridge frontend + federation + starbases"
Created-By: ""
Created: ""
Assigned-To: ""
Doc-Ref: "— no branch/PR yet"
Migrated-From: d4e5fe5cf9203b2f88f811ad9184769d91c2ce77
Tags: "starfleet"
Slug: long-term-fleet-architecture-vision-bridge-command-frontend

Triggered by an Enterprise research request into **Paperclip AI** (`github.com/paperclipai/paperclip`, MIT, self-hosted
agent-orchestration platform — Node/React/Postgres, org-chart/governance, atomic task checkout, budget/token tracking,
git-based workspaces, web dashboard, explicit Claude Code adapter). **Praetor's explicit intent: do NOT adopt/integrate
Paperclip itself** — instead treat it as a reference architecture to learn from, and evolve `starfleetctl` incrementally
toward equivalent capabilities natively (budget/cost tracking and structured task/goal tracking are the concrete gaps
Paperclip's docs made obvious — currently `DASHBOARD.md` + `comms`/`pr-claim` cover this ad hoc, with no cost
accounting at all). **Command frontend is a deliberately different, non-Paperclip direction: a literal
Star-Trek-bridge-style command center** — large monitor/TV + voice interface + interactive on-screen display, not a
browser dashboard tab. Fits the existing ship-name/fleet theme (see "Ship names for fleet identity" in `AGENTS.md`)
rather than importing Paperclip's web UI wholesale. **Next horizon after the current 5 phases — meta-commandeering
across possibly-separate workspaces**, not just coordination within one `mpbt-workspace` checkout: goal is **security
isolation** — individual agents/fleets working in separated, decentralized execution areas (e.g. workers on different
machines, or provisioned on-demand in a k8s cluster), rather than everything running on one host sharing one
`.starfleet-ai/var/comms/` directory as today. Two concrete next-step options raised by the praetor (**not yet
decided/committed, no ship assigned**): (1) a **real network interface** for cross-host communication/coordination —
supersedes the current file-based polling model (`.starfleet-ai/var/comms/`, `flock`-serialized, single-host by construction)
with something that actually works across machines; revisits the earlier "would pipes/sockets beat polling" discussion,
but now motivated by the multi-host goal, not just local efficiency. (2) **autonomous background agents that don't need
an interactive Claude Code client in the loop at all** — likely means driving agents via the Claude Agent SDK/API
directly for always-on headless workers, instead of today's model of orchestrating real `claude` CLI sessions inside
`tmux` (`agent-run`/`agent-attach`). Both are genuinely new architecture, not incremental script work — do not start
implementation without the praetor picking a direction first. **2026-07-06 (praetor): concrete shape for the
multi-host/isolation piece — "Starbases."** Fleet control becomes (optionally) network-capable, and the fleet is
organized into multiple **Starbases** (Star-Trek terminology, fits the existing ship/fleet theme — a starbase is a fixed
installation ships dock at) — each Starbase corresponds to one machine, or one separated OS user on a shared machine.
**Hard consequence: starbases do NOT share a filesystem.** This makes the network-interface option above a genuine
*requirement* for cross-starbase coordination, not just a nice-to-have — today's entire
`comms`/`pr-claim`/`ws-commit`/`with-clone-lock` model is built on one shared `.starfleet-ai/var/` directory tree on one
filesystem (flock-serialized files), which structurally cannot span starbases as defined. Implication for whenever this
gets designed: within a single starbase, the current file-based model can stay (it works and is well-tested); *between*
starbases needs an actual network protocol/service. **2026-07-06 (praetor): first concrete step approved — start moving
`comms` and `dashboard` onto a socket-based interface, Unix domain sockets first (not TCP/network yet).** This is
the "don't start implementation" gate now explicitly opened, but only for this specific, scoped first step — the rest of
the starbase/network vision above is still unscoped. **Claimed by Constellation, 2026-07-06 — design sketch below, then
build+isolated-test (directive m0076).** **Design:** new subcommand namespace `bridged` (bridge daemon) — `starfleetctl
bridged run [--socket <path>]` (foreground; caller backgrounds it via tmux/`agent-run`/`nohup` like every other
long-lived fleet process here, deliberately **no** self-daemonization/fork — matches this workspace's existing
convention rather than inventing process supervision) and `bridged status` (connect+report up/down). **Socket:**
`.starfleet-ai/var/comms/bridged.sock`, mode 0600. **Wire protocol:** length-prefixed JSON frames (`<4-byte big-endian uint32
length><JSON>`, both directions) — chosen over newline-delimited JSON to avoid any reliance on JSON payloads never
containing a raw newline, and because length-prefixing is the standard transport-agnostic framing (works unchanged over
a future `net.Listen("tcp", ...)`, satisfying the TCP-extensibility requirement without redesign). One request/response
per connection for v1 (`{"cmd":"comms"|"dashboard","args":[...]}` → `{"exit_code":0,"stdout":"...","stderr":"..."}`)
— mirrors the existing one-shot-process-per-CLI-call model exactly, so it's a drop-in alternative transport for the same
operations rather than a new streaming/session protocol. **Concurrency:** connections accepted concurrently, but command
*execution* serialized behind one mutex — `agentbus.Run`/`dashboard.Run` are CLI-shaped (print to process-wide
`os.Stdout`/`os.Stderr`, return an int exit code) rather than writer-injectable, so capturing one call's output means
temporarily swapping `os.Stdout`/`os.Stderr` to a pipe for that call's duration; the mutex just protects that swap from
cross-talk, reusing the existing tested command logic unmodified instead of forking a second implementation. (File-level
correctness was never resting on this mutex — `agentbus`/`dashboard` already serialize real mutations via `flock`
independently.) **Lifecycle/crash-safety:** startup does a liveness probe before binding — `net.Dial("unix", path)`;
success means a live daemon already owns the socket (refuse to start a second one, clear error); failure (stale
file/`ECONNREFUSED`/`ENOENT`) means unlink-and-bind-fresh — same `unix_socket_is_live()`-style pattern already used for
`pr-checkout`'s listener creation (`internal/ghpr`). Clean shutdown (SIGINT/SIGTERM) removes the socket file; an unclean
exit (SIGKILL/crash) leaves it behind exactly like any other stale-socket scenario, self-healing on the next `bridged
run` via the same startup probe — no separate cleanup step needed. **Auth:** 0600 socket file (same trust boundary as
the file-based model today — anyone who can already read/write `.starfleet-ai/var/comms/*` has full access regardless), plus
`SO_PEERCRED` verified per-connection (reject a connecting UID that doesn't match the daemon's own) as defense in depth.
Explicitly flagged: `SO_PEERCRED` is Unix-socket-only and won't carry over to a future TCP transport — that gap needs
its own solution (e.g. a shared token) whenever cross-host support is actually scoped, not pretended away now.
**Scope:** only `cmd:"comms"` and `cmd:"dashboard"` dispatchable for this step (matches the directive) — the
dispatcher is written generically enough to add more later, but nothing else is wired yet. **Test plan:** isolated
worktree, tested against a **scratch** `.starfleet-ai/var`-shaped directory, never the live production one — round-trip for both
command families, concurrent-connection safety (parallel clients, no interleaved/corrupted output), stale-socket
recovery (`kill -9` the daemon, confirm the next `run` cleans up and rebinds), refuse-second-instance, and
clean-shutdown socket removal. **No wiring into any hook/script/existing caller** — stays a standalone, opt-in new
subcommand only, per the additive-only constraint. Non-negotiable constraints carried over from every other cutover this
session: (1) **additive, not a replacement** — the existing file-based/`flock`-serialized model (`.starfleet-ai/var/comms/*`,
`<gitdir>/mpbt-clone.lock`) keeps working completely unchanged; a socket daemon is a *new, parallel* access path, not
something bash originals or any existing caller gets migrated onto yet. (2) **`comms` is still the fleet's live,
single point of coordination** — a daemon crashing must not take down anything that currently works; no existing caller
(hooks, Monitor-loop scripts, any ship's direct file/CLI access) should depend on the daemon being up. (3) Genuinely new
territory for this codebase: a **long-running daemon process** (socket listener, connection handling, a wire protocol)
where everything built so far has been stateless one-shot CLI invocations against shared files — treat the daemon's
lifecycle (start/stop/crash/restart, concurrent-connection handling, socket file permissions/cleanup on an unclean exit)
with the same rigor as the file-locking code got. (4) This is explicitly the first concrete step toward the "Starbase"
network requirement above — design the wire protocol/message shape with an eventual TCP transport in mind (even though
only Unix sockets are being built now), so this isn't thrown away when cross-host support is scoped later.**Build done,
2026-07-06 (Constellation), `starfleetctl@79cb7c5` — `internal/bridged/` package + `bridged run`/`bridged status`
subcommands.** Implements exactly the design above (length-prefixed JSON frames, `.starfleet-ai/var/comms/bridged.sock` @ 0600,
`SO_PEERCRED` check, allowlist-gated `comms` dispatch, mutex-serialized `os.Stdout`/`os.Stderr` capture around
`agentbus.Run`/`dashboard.Run`, stale-socket self-healing, clean-shutdown socket removal). **Safety-critical finding
during design, not just implementation:** `agentbus.Run()` also dispatches `ask` (blocks polling for a reply, calls
`os.Exit(3)` on timeout — would kill the *entire daemon*, not just fail one request) and
`monitor-loop`/`fleet-watch`/`watch` (each an intentionally infinite loop). Guarded with an explicit **allowlist** (not
a blocklist) of the known-quick comms subcommands, so a future subcommand that turns out to block is safe-by-default
(rejected) rather than silently daemon-reachable. **Verified:** full `go test ./internal/bridged/... -race` suite (ping;
comms round-trip; dashboard round-trip incl. the new `theme`/`reindex` subcommands, which pass through unchanged
since dashboard's arg list isn't allowlisted; all four dangerous subcommands rejected *and* the daemon still responsive
immediately after; 20 concurrent connections with no corrupted/interleaved output; stale-socket recovery via
`SetUnlinkOnClose(false)` to faithfully simulate a crash rather than a graceful `Close()`, which Go auto-unlinks;
refuse-second-instance; clean-shutdown socket removal) — all pass. Also manually smoke-tested end to end through the
compiled binary as a real background process with a separate client process, not just same-process goroutines. **Two
real findings along the way:** (1) the default socket path can exceed the ~108-byte Unix `sun_path` limit (hit for real
with a deeply-nested test path, surfaced as a cryptic "invalid argument") — added an explicit length check with a clear
error on both server and client sides; the real production path (`.../mpbt-workspace/.starfleet-ai/var/comms/bridged.sock`, 66
bytes) is nowhere near the limit, but a nested worktree/scratch path easily can be. (2) **Known v1 limitation,
documented not silently punted:** the daemon's `STARFLEET_SHIP_ID` is fixed at process-start from its own environment, not
per-request — so one running daemon instance reports everything under one fixed identity. Fine for a single agent making
many calls; a true shared *multi-agent* daemon (the direction the Starbase vision implies) would need the identity
threaded through the request instead — not solved here, v1 stays scoped to proving the transport works. **Not wired into
any hook/script/existing caller, no `AGENTS.md`/`.claude/settings.json` cutover** — purely additive, opt-in via
`starfleetctl bridged run`/`status` only, per the standing rule. **Next:** praetor/Enterprise decide whether this is
worth extending (per-request identity, more `cmd` families, eventually a TCP listener) before any further investment.

**Per-request identity added, 2026-07-06 (Constellation), `starfleetctl@818167f` — praetor go-ahead via Enterprise
(m0082), retrofitting the v1 limitation flagged above.** `Request` gained an optional `env` field (`map[string]string`),
backward-compatible when absent (falls back to the daemon's ambient environment exactly like v1). Only an explicit
allowlist of identity keys is honored — `STARFLEET_SHIP_ID`, `XLIBRE_RELEASE`, `PROJECT`, `AGENT_HANDLE` — deliberately **not**
infra-level vars like `STARFLEET_BUS_DIR`/`STARFLEET_STARFLEET_BUS_TTL`, which would let one caller silently redirect another's request at a different
bus directory entirely, a different feature from "each request carries its own identity". Implementation follows
Enterprise's proposed design: `os.Setenv`/`Unsetenv` is exactly as much global process state as the
`os.Stdout`/`os.Stderr` swap-and-capture trick already serializes, so env override+restore happens inside the *same*
`execMu` critical section — set before `fn()`, restored (re-set to the prior value, or unset if it wasn't set before)
after, before the mutex releases. Two overlapping requests with different identities can never observe each other's
`STARFLEET_SHIP_ID`, because only one `fn()` ever executes between an override and its restore. **Verified with the specific test
Enterprise's directive asked for** (`TestPerRequestIdentityNoLeakage`): 15 concurrent requests each with a distinct
`STARFLEET_SHIP_ID` override correctly post/read back their own identity; the resulting board shows all 15 as distinct rows
(proves the writes landed under the right identity, not just that responses echoed the right name); a final
unspecified-`env` request falls back to the ambient (still-unset) identity rather than leaking the last override (proves
restoration actually ran, not just that concurrent calls happened not to collide). Full suite (10 tests) passes under
`go test -race`. Still additive, no cutover — a shared daemon serving many differently-identified agents is now
architecturally sound, but nothing yet actually connects to it in production. **Next:** praetor/Enterprise decide
whether further investment (more `cmd` families, a TCP listener, actual production wiring) is worthwhile.
