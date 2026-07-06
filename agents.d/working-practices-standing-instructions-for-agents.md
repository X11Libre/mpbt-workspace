---
slug: working-practices-standing-instructions-for-agents
title: "Working practices (standing instructions for agents)"
order: 20
---

## Working practices (standing instructions for agents)

These apply to **every** session — they keep knowledge and tooling from decaying as sessions are
cleared:

- **Language policy (2026-07-06): converse with the praetor in German, everything else in
  English.** Any direct communication with the praetor — chat replies, `agent-bus tell`/
  `broadcast` text directed at them, status notes meant for them to read — is in German. Anything
  that becomes part of the project's durable artifacts stays English: code, code comments, commit
  messages, PR titles/descriptions/review comments, other GitHub interactions, and files like
  `AGENTS.md`/`DASHBOARD.md`/topic docs. Applies fleet-wide, not just to the flagship session.
- **Record lessons learned in this file as you go.** Whenever you discover something non-obvious —
  a failure mode and how it presents, a gotcha in a workflow/script, a fact that took real digging
  to establish — append it to the relevant section of `AGENTS.md` (and the topic docs like
  `NVIDIA-ABI.md`) **within the session**, not at the end. Session context is wiped on `/clear`;
  only what's written here survives. Prefer a concise durable note over re-deriving it next time.
- **Keep `DASHBOARD.md` current — it's the cross-session "what's in flight / what got parked"
  index.** `agent-bus`/`pr-claim` are TTL'd live-status (minutes/hours); nothing durable tracked
  *themes* until now, so half-started ideas got lost between sessions. When you start, pause, or
  finish a theme (an initiative spanning more than one PR, or a decision still pending), update its
  entry **in the same session** — same rationale as the lessons-learned rule above.
  **Restructured 2026-07-06 (directive m0048/m0073): `DASHBOARD.md` itself is now a thin,
  mechanically-generated index — the actual content for each theme lives in its own file under
  `dashboard/themes/<slug>.md`** (Markdown body + a small YAML frontmatter block: `slug`/`title`/
  `category`/`status` or `noted_by`+`since`/`doc_ref`/`migrated_from`). This fixes the file's worst
  scaling problem — most concurrent edits used to collide on one shared file even though they
  touched unrelated themes; now two ships editing two different themes touch two different files
  and never collide. **Editing a theme is still just `Read`/`Edit` as always** — open
  `dashboard/themes/<slug>.md` directly, no new tool required for the content itself. What's new:
  `scripts/starfleetctl dashboard theme list [--json]` (overview), `theme show <slug>` (print one
  file), `theme new <slug> --title "<t>" [--status "<s>"] [--parked]` (scaffold a fresh theme),
  and `theme commit <slug> -m "<msg>" [--no-push]` (commit+push **just that one file**, under the
  same shared clone lock `ws-commit`/`dashboard commit` already use — this is the actual
  concurrency fix, not a bigger hammer). After editing a theme file directly with `Edit` (not via
  `theme write`), commit it the normal way (`scripts/ws-commit -m "<msg>"
  dashboard/themes/<slug>.md`) — `theme commit` is just a convenience wrapper scoped to one path,
  not a requirement. **`DASHBOARD.md`'s own thin index is regenerated, never hand-edited:**
  `scripts/starfleetctl dashboard reindex` rebuilds both tables from every theme file's
  frontmatter and is a pure function of the current file set (sorted by slug) — two ships racing a
  reindex converge to the same byte-identical output, and running it twice in a row is a no-op
  (verified). Run it after adding/removing a theme file or changing a `status`/`title`/`category`
  field, so the index reflects the change; don't touch the `## Aktive Themen`/`## Parkplatz` tables
  in `DASHBOARD.md` by hand, that diff just gets clobbered by the next `reindex`. Cross-reference
  another theme with `[[slug]]` (textual convention, not an auto-resolving link — mirrors how
  Claude Code's own per-user memory files reference each other). Full design rationale, including
  the two things deliberately kept out of scope (ship/agent live status stays in `agent-bus
  board`; full git history per theme isn't achievable across a content split), in
  `DASHBOARD-RESTRUCTURE.md`.
- **Notice something worth a look while doing unrelated work → add it to `DASHBOARD.md`'s
  Parkplatz immediately, don't just mention it in the response and move on.** A suspicious code
  path, a possible follow-up cleanup, an untriaged idea, a "this looks wrong but is out of scope
  right now" — the moment you'd otherwise say it in passing and keep going, add a Parkplatz row
  instead (one line: thema, where it was noticed — file/PR/commit, today's date, short why). This
  is the main way `DASHBOARD.md` stays populated: most finds happen as a side effect of other work,
  not during a dedicated triage pass. Don't add
  individual PRs or ephemeral status there; it links out to the detail doc/branch/PR instead of
  duplicating GitHub or `agent-bus`.
- **You may commit + push directly, without asking, on the praetor's `mtx/*` workspace
  branches — any file, not just `AGENTS.md`.** Standing grant from the praetor (broadened
  2026-07-02; originally scoped to `AGENTS.md` only): on `mtx/agent-config` (and other `mtx/*`
  branches), commit and push straight away whenever it's warranted — lessons/notes in `AGENTS.md`,
  `DASHBOARD.md` updates, new/changed `scripts/*`, config tweaks, whatever the session produced.
  Use `scripts/ws-commit -m <msg> <path...>` so it goes through the `with-clone-lock` mutex. No
  confirmation needed on those branches. (Other branches — anything not `mtx/*` — still follow the
  normal "ask before committing" rule.)
  **What `mtx/*` is for:** it's the praetor's **personal staging branch** — freely accumulate
  lessons/docs/tooling there without asking each time. It is **not** auto-merged into `master`.
  Generalizing something onto `master` (so other users/contributors benefit, not just the
  praetor) is a deliberate, separate, later decision the praetor makes per item — don't
  propose or perform that promotion unprompted.
- **Project knowledge lives in this repo, not in per-user agent memory.** Lessons, CI gotchas,
  failure modes, workflow quirks and PR-repair findings go into `AGENTS.md` or a topic doc
  (`NVIDIA-ABI.md`, `CI-GOXTS-XEPHYR.md`, …) — version-controlled and shared with the whole team
  and with headless/CI runs. A machine-local per-user agent memory store (e.g. Claude Code's
  `~/.claude/.../memory/`) is private and invisible to teammates, so it must **not** hold project
  facts; reserve it for genuinely user-specific, cross-project preferences. And **never** create a
  `memory/` directory inside a source clone — it sits untracked in the upstream tree where a stray
  `git add -A` could commit it.
- **Turn repeated commands into scripts, then authorize them.** If you find yourself running the
  same multi-step command (especially GitHub/`gh` access like fetching CI job logs, querying
  checks, editing PR bodies), factor it into a generic `scripts/<name>` (match the existing style:
  `set -euo pipefail`, `REPO="${REPO:-X11Libre/xserver}"`, a `--help` banner, sane defaults) and
  add allow rules so it runs without a confirmation prompt. Add **both** forms —
  `Bash(scripts/<name>)` (no-arg invocations) **and** `Bash(scripts/<name> *)` (with parameters);
  the ` *` wildcard does *not* cover the bare call, so a no-arg run would still prompt without it.
  Invoke scripts as `scripts/<name>` (the relative form every rule matches), not by absolute path.
  Put the rules in the **checked-in `.claude/settings.json`** (committed, team-wide, durable) —
  *not* `.claude/settings.local.json`, which is gitignored and continuously rewritten by the
  harness's permission tracker, so hand edits there get clobbered. All of `scripts/*` is already
  authorized this way. Document the new script in the Key
  commands table. This is why `pr-job-logs`, `pr-checkout`, `pr-amend-push`, `show-branch-file`,
  `backport-applies`, etc. exist and are pre-authorized in `.claude/settings.json`.
- **C booleans: use `bool` (`<stdbool.h>`), not Xlib's `Bool`.** The legacy `Bool`/`TRUE`/`FALSE`
  typedef is being **phased out**. For any **newly introduced** boolean (variable, struct field,
  return type), use C99 `bool`/`true`/`false` and `#include <stdbool.h>`. Don't do sweeping
  `Bool`→`bool` churn in unrelated code, but prefer `bool` in new/rewritten code and when a change
  already touches the declaration. (First applied: the `shmSupported` flag in the `xf86bigfont`
  pagesize cleanup, PR #3201.)
- **Bash cwd persists silently across tool calls — after `cd`-ing into a nested clone under
  `_WORK_/` for one investigation, every later command in that session (including unrelated ones
  like `apt-get source`, `stat`, `git status`) keeps running there until you explicitly `cd` back
  or use absolute paths.** Bit twice in one session (2026-07-01): (1) it made an unrelated `git
  status`/`stat` on `mpbt-workspace/DASHBOARD.md` fail and look like file corruption, when the real
  cause was just running from inside an xserver agent clone; (2) `apt-get source libfontenc1` /
  `libxfont2` — run for read-only upstream-source investigation, not meant to touch any repo — each
  download into whatever the *current* cwd happens to be, once **inside the xserver clone itself**
  (leaving stray `libfontenc-1.1.8/`, `.dsc`, `.orig.tar.gz` etc. as untracked files in a shared
  clone) and once in the `mpbt-workspace` root. **Always `cd` into the scratchpad dir (or pass an
  absolute output path) before any ad-hoc source/package fetch for investigation** — never rely on
  "wherever cwd currently is" for a command whose output isn't meant to land in a repo.
- **Opening URLs (e.g. PR links) in the praetor's browser.** In an **interactive local session**
  the Bash tool shares the praetor's desktop session (`DISPLAY` set, dbus reachable), so you can
  open a link in their running browser with a plain local command — handy for handing over a PR to
  review. Do it **only on explicit request** (it's a visible side-effect on their desktop), and
  never in headless/CI runs (no display). The exact browser command is a per-user setting (don't
  hard-code a browser here — `xdg-open` follows the user's system default, which may not be the
  browser they actually use).
