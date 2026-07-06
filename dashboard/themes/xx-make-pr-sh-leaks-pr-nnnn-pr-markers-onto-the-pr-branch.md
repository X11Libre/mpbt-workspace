---
slug: xx-make-pr-sh-leaks-pr-nnnn-pr-markers-onto-the-pr-branch
title: "`xx-make-pr.sh` leaks `[PR #NNNN]`/`PR:` markers onto the **PR branch** (not just the incubator)"
category: parked
noted_by: "`AGENTS.md` \"PR workflow\""
since: "2026 (found via PR #3162)"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Root cause: `DEFAULT_MODE="rebase"` applies the marker rewrite to `$BRANCH_NAME` too, because the clean `incubator`-only mode needs interactive `git rebase -i` (unsupported here). Fix: scope the marker `--exec` to the incubator rebase only, make that path non-interactive (`GIT_SEQUENCE_EDITOR=true`, no `-i`). Until fixed, every `xx-make-pr.sh`-created PR needs a manual clean-subject check before merge
