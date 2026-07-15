
## Backport workflow (master PR → release branches)

> **NEVER auto-merge into `release/*` branches.** Merges into any release line
> (`release/25.2`, `release/25.1`, `release/25.0`, …) happen **only manually, by the praetor**.
> A green CI run and a clean bot-review are **not** sufficient to merge a release PR — agents open
> and cross-link the PR and then **stop**. Fixes for existing releases must always be reviewed
> independently and manually (applicability + correctness, confirmed per branch), regardless of CI
> status. (Auto-merge is only ever acceptable on `master` PRs — and even there only when the user
> explicitly asks for it.)

Backporting a merged **master** PR means applying its changes to every applicable release
line, each worked in **its own clone**. Agents must use a dedicated agent-owned clone created
with `.starfleet-ai/bin/starfleetctl github pr mk-agent-clone <release>` (see Concurrency / isolation) — not the user's
hand-edited `_WORK_/xserver-<release>/sources/xlibre/xserver` tree. Switch to the matching
release; don't try to do it all from one clone.

Each release clone has a dedicated incubator branch and a matching `make-pr.upstream-branch`:

| Clone | Incubator branch | `make-pr.upstream-branch` |
|-------|------------------|---------------------------|
| `xserver-25.2` | `rfc/backport-25.2` | `release/25.2` |
| `xserver-25.1` | `rfc/backport-25.1` | `release/25.1` |
| `xserver-25.0` | `rfc/backport-25.0` | `release/25.0` |

(Each future major release adds its own clone + `rfc/backport-<release>` branch.)

Procedure, per applicable release:

0. **Check whether it's already been backported before doing anything else:**
   `gh pr view <master-pr#> --repo X11Libre/xserver --json body -q .body` — if a "Backport
   dashboard" table is already present, another (possibly now-finished/invisible-on-the-board)
   session already did this PR; read the linked backport PR numbers instead of re-running the
   workflow. Skipping this step produces byte-identical duplicate PRs and duplicate cherry-picked
   commits in the shared `rfc/backport-<release>` incubator. (Hit 2026-07-03: `agent-bus board`
   only shows *currently running* agents — a session that finished before a suspend/reboot leaves
   no trace there, so the board being "empty of workers" does NOT mean a PR hasn't already been
   backported. Recovered cleanly because `github backport commit`'s incubator rebase never got pushed —
   the divergence was caught locally — but always check first regardless.)
1. **Check applicability** by inspecting the actual code on that branch — the fix may already
   be present, or the buggy code may not exist / not be vulnerable there. (See
   `VULN-FIX-BACKPORT.md` for an example applicability matrix.) Use
   `scripts/starfleetctl github pr show-branch-file <release-branch> <master-path> '<symbol>'` to read the relevant
   function on each release branch straight from GitHub (it auto-resolves the
   `Xext/<ext>/` ↔ `<ext>/` directory reorg between newer and older releases). If it's already
   contained or N/A, **don't open a PR** — just record that in the dashboard.
2. **Apply + submit in one shot** with `scripts/starfleetctl github backport commit <release> <commit-ish|PR#>`. It
   refreshes the isolated agent clone (`github pr mk-agent-clone`), `cherry-pick -x`'s the commit onto
   `rfc/backport-<release>` (keeping the original message + `Signed-off-by` and appending the
   `(cherry picked from commit <sha>)` line), then runs `github pr make` to push the PR against
   `release/<release>` and mark the incubator with a `[PR #NNNN]` prefix + `PR:` trailer.
   Passing a PR number resolves its merge commit automatically. If the cherry-pick fails only
   because the file moved (the `Xext/<ext>/` ↔ `<ext>/` reorg between master and the older
   releases), it auto-remaps the diff's paths and applies it, reconstructing the same commit —
   so cross-reorg backports are one-shot too. Only a genuine **content** conflict bails; then
   you do a manual/adapted backport in the agent clone and `scripts/starfleetctl github pr make <sha>` from
   inside it.

   (The underlying `.starfleet-ai/bin/starfleetctl github pr mk-agent-clone` + `cherry-pick -x` + `github pr make`
   steps can still be run by hand if you need finer control — `github backport commit` just chains them.)

**Cross-linking (required):**

- The **original master PR** gets a "Backport dashboard" table appended to its description —
  one row per target branch with its backport PR (or `—`) and status
  (`✅ Merged` / `🔄 Open` / `✅ Already contained`).
- Each **backport PR** links back to the original master PR.
- `gh pr edit` currently fails on the xserver repo with a GraphQL *"Projects classic
  deprecation"* error, so edit PR bodies via the REST API. Use
  `scripts/starfleetctl github pr set-body <pr#> <body-file>` (wraps
  `gh api --method PATCH repos/X11Libre/xserver/pulls/<n> -F body=@<file>`) — write the new body
  to a file first, then apply it.
