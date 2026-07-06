---
slug: file-layout-reminder
title: "File layout reminder"
order: 230
---

## File layout reminder

- `.gitignore` only ignores `/_WORK_/`
- One git branch: `master` (the `wip1` branch this once mentioned no longer exists — checked
  `git branch -a` + `gh api repos/X11Libre/mpbt-workspace/branches`, 2026-07-01; agents work off
  their own `mtx/*`/task branches instead)
- Remote: `git@github.com:X11Libre/mpbt-workspace.git`
- **License:** `LICENSE` (AGPL-3.0-or-later, canonical FSF text) covers this workspace's own
  tooling — see the "Licensing policy" section above for the full scope (this repo vs.
  xserver/driver clones) and the current new-files-only, not-yet-retroactive status.
