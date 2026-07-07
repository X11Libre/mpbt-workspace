---
slug: xx-make-pr-sh-leaks-pr-nnnn-pr-markers-onto-the-pr-branch
title: "**RESOLVED** — `xx-make-pr.sh` leaked `[PR #NNNN]`/`PR:` markers onto the **PR branch** (not just the incubator)"
category: parked
noted_by: "`AGENTS.md` \"PR workflow\""
since: "2026 (found via PR #3162)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Root cause: `DEFAULT_MODE="rebase"` applied the marker rewrite to `$BRANCH_NAME` too, because the clean `incubator`-only mode needed interactive `git rebase -i` (unsupported here).

**Fixed 2026-07-07 (Intrepid), in both implementations:** `scripts/xx-make-pr.sh` and the `starfleetctl xx-make-pr` Go port (`mpbt-hq/starfleetctl@e7341a0`) now always mark only the incubator branch, via a scripted `GIT_SEQUENCE_EDITOR` that appends `exec` after just the todo lines for the submitted commits (what a human doing `rebase -i` by hand would type) — the pushed PR branch is never touched again after the push. The `--rebase`/`incubator` mode split and its CLI flag are gone; there is only one, correct, non-interactive path now. Verified end-to-end against a scratch repo (stub `gh`) for both implementations: incubator gets the `[PR #N]`/`PR:` markers, the pushed/mergeable branch stays byte-clean. Docs updated: `README.md`, `agents.d/pr-workflow-scripts-xx-make-pr-sh.md`, `agents.d/key-commands.md`, `agents.d/starfleetctl.md`, and the starfleetctl repo's own `README.md`.

Any PR created with the *old* script (before this fix) may still carry the leaked prefix in its merged subject line — no retroactive history rewrite on master.
