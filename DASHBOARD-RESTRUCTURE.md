# DASHBOARD.md restructuring — design proposal

Design task from directive m0048 (Enterprise + praetor, 2026-07-06): `DASHBOARD.md` is scaling
poorly — individual rows (e.g. "starfleetctl") have grown into wall-of-text single cells, and
every session that wants to update one theme has to `pull`/edit/`commit` the *entire* file, which
is why concurrent theme updates keep colliding (see the `scripts/dashboard`/`ws-commit` "modified
by another session" notes scattered across `AGENTS.md`). This doc is the **design only** — no
implementation yet, per the directive ("reines Design-vor-Implementierung-Thema"). Claimed in
DASHBOARD.md's Aktive-Themen table by Potemkin, 2026-07-06.

**Explicitly out of scope** (per the directive): ship/agent live status. `agent-bus board` already
covers that (live, TTL'd) — folding it into this restructuring would just create a second,
faster-staling copy of the same data.

## The four questions, and the recommendation for each

### 1. Per-theme file format: Markdown, or structured (YAML/frontmatter)?

**Recommendation: Markdown body + a small YAML frontmatter block**, i.e. exactly the format
Claude Code's own per-user memory files already use (the directive's own point of comparison) —
`---\nname: ...\nstatus: ...\n---\n<prose>`.

Why not pure YAML: today's theme content is inherently narrative — bolded phrases, inline code
spans, links, occasional code blocks, multi-paragraph "what happened and why" writeups. Forcing
that into YAML scalars/lists would be a worse authoring experience for zero query benefit (nobody
is going to `jq`-style-query prose). Why not plain Markdown with no frontmatter at all: the whole
point of this restructuring is a *thin, mechanically-derivable* index in `DASHBOARD.md` itself —
that needs a few structured fields (title, status, one-line summary, last-touched-by/date) pulled
from each file without parsing prose heuristically. Frontmatter gives exactly that, cheaply, and
mirrors machinery every session here already knows from the memory-file convention.

Proposed frontmatter fields (kept deliberately small):

```yaml
---
slug: starfleetctl          # matches the filename (dashboard/themes/<slug>.md), used for [[slug]] refs
title: "starfleetctl: consolidate flock/race-prone agent-scripts into one Go CLI"
status: active               # active | parked | done
since: 2026-07-03             # first-touched date, carried over from today's tables
owner: Farragut               # last ship/human to materially update it; informational, not a lock
---
```

`status: done` themes are **not deleted** — they stay as an audit trail (mirrors today's practice
of leaving a closed-out row in place with a "DONE" note, e.g. the security-fix-worktrees Parkplatz
row) but drop out of the index's default view (see `reindex` below).

No `parked`-vs-`active` *directory* split (e.g. `dashboard/themes/active/` vs `.../parked/`) —
that would force a file move (and slug/`[[ref]]` churn) on every status transition. A flat
`dashboard/themes/<slug>.md` directory with `status:` as the only thing that changes on a
transition is strictly less churn.

### 2. `starfleetctl` frontend commands

Extend the existing `dashboard` subcommand (own repo `mpbt-hq/starfleetctl`, already has
`pull`/`show`/`write`/`commit` for the whole-file today — see `internal/dashboard/`) rather than
inventing a parallel command family:

```
starfleetctl dashboard theme list [--status active|parked|done]   # index, from frontmatter only
starfleetctl dashboard theme show <slug>                          # print one theme file
starfleetctl dashboard theme write <slug> <file|->                # replace one theme file's content (no commit)
starfleetctl dashboard theme commit <slug> -m "<msg>" [--no-push]  # commit+push JUST that one file
starfleetctl dashboard theme new <slug> --title "<t>" [--status active]   # scaffold with frontmatter
starfleetctl dashboard reindex                                    # regenerate DASHBOARD.md's thin index from all theme files
```

`reindex` is the concurrency win: today's collisions happen because the index *and* every theme's
prose live in one hand-edited table in one file. Once the index is **mechanically regenerated**
from frontmatter (never hand-edited), two ships updating two different themes touch two different
files under `dashboard/themes/` and never collide; `reindex` running afterward is a deterministic,
idempotent, conflict-free operation (regenerate-and-overwrite, not a hand-merged diff) — and if two
`reindex` runs *do* race, the result is byte-identical either way since it's a pure function of the
current file set, so a `pull --rebase` retry always converges. This is the same reasoning already
applied to `agent-bus board`'s deterministic sort order.

`theme commit` reuses the identical `<gitdir>/mpbt-clone.lock` + `pull --rebase --autostash`
pattern `internal/dashboard`'s whole-file `commit` already implements — just scoped to one path
instead of `DASHBOARD.md`. No new locking primitive needed.

The whole-file `pull`/`show`/`write`/`commit` stay (some callers may still want "give me
everything," e.g. a fresh session orienting itself) — this is additive, not a breaking change to
the existing subcommand.

### 3. Migration path (no history loss)

Full fidelity isn't achievable with git alone: this is a **content split** (many rows in one file
→ many files), not a rename, so there's no single `git mv` that carries a row's history forward.
Being honest about that limitation up front beats overpromising:

- Do the migration as **one single, purely-mechanical commit**: for each current Aktive-
  Themen/Parkplatz row, create `dashboard/themes/<slug>.md` with frontmatter derived from the
  row's own "Notiert/Seit" columns and the row's prose copied verbatim into the body (no rewording
  — a copy-out, not a rewrite, so nothing is silently lost or "improved" mid-migration).
  `DASHBOARD.md` shrinks to the thin index in the same commit.
- Record the pre-migration commit SHA in every theme file's frontmatter as `migrated_from: <sha>`
  (of `DASHBOARD.md` at that commit). Anyone doing archaeology on a theme's pre-split history runs
  `git log <sha> -- DASHBOARD.md` and greps for the old row text — one indirection, not lost
  entirely.
- Slugs should match each row's existing informal identifier where the table already used one
  (`starfleetctl`, `mpbtctl` era notwithstanding) — don't invent new names gratuitously, so
  existing prose that already says "the starfleetctl row" keeps meaning the same thing.
- Do the migration itself from an isolated `scripts/worktree add` checkout of mpbt-workspace, not
  the shared interactive one — it's a big mechanical diff touching every row at once, exactly the
  kind of change that should not race a concurrent session's normal DASHBOARD.md edit mid-flight.

### 4. Cross-references between themes

**`[[slug]]`**, exactly like the memory system (the directive's own suggested model) — and this is
already an established informal convention in this exact file today: the Telegram-integration
Parkplatz row already writes `[[prefers-self-hosted-no-cloud]]` to point at a Claude-memory file
slug. Extending the same bracket convention to mean "another file under `dashboard/themes/`" when
used *inside* a theme file is a natural, zero-new-syntax generalization — not a new mechanism.

No auto-resolving link tooling is proposed (same as the memory system's own stance: "a `[[name]]`
that doesn't match an existing memory yet is fine — it marks something worth writing later, not an
error"). `[[slug]]` stays a textual, grep-able convention for humans/agents, not a rendered
hyperlink — GitHub's Markdown renderer doesn't resolve double-bracket wiki-links anyway, so
promising more than that would be misleading.

## Non-goals / explicitly deferred

- Ship/agent live status (per directive — `agent-bus board` already owns this).
- Auto-migrating the *topic* docs (`NVIDIA-ABI.md`, `CI-GOXTS-XEPHYR.md`, etc.) into
  `dashboard/themes/` — those are already standalone, already work, and Aktive-Themen rows that
  reference them today (via the "Doc / Branch / PR" column) can keep doing so unchanged; a theme
  file just links out the same way the table row does today.
- Deciding *when* to actually run the migration — that's the praetor's call once this design is
  reviewed, same as every other "ready but not executed" item on the board.

## Status

Design proposal complete, 2026-07-06 (Potemkin). Not yet implemented — awaiting fleet/praetor
review per the directive. See DASHBOARD.md's Aktive-Themen row for this theme for the current
disposition.
