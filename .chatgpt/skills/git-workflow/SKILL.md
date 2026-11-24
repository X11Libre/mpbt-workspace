---
name: git-workflow
description: Use when planning or making Git changes in the user's repositories through an available GitHub connection.
---

# Git workflow

## Before writing

- Confirm the repository and exact target branch. For ChatGPT workspace configuration, use `X11Libre/mpbt-workspace:mtx/agent-config` unless the user says otherwise.
- Inspect the current branch head and the target files. For file updates, use the current blob SHA; for ref updates, use an expected head SHA.
- Check whether the requested path already exists and whether the change belongs in this repository.

## Change construction

- Keep commits focused and atomic. Do not combine unrelated fixes merely because they touch the same repository.
- Preserve existing file content and formatting; make the smallest justified edit.
- Do not rewrite history, force-push, merge, rebase, delete branches, or change default-branch content unless explicitly requested.
- Never claim to have changed a local checkout. GitHub connector writes affect the remote repository only.

## Verification and reporting

- Re-fetch the branch and changed files after writing.
- Report the repository, branch, commit SHA, and exact paths changed.
- Distinguish a successful GitHub write from local checkout state, CI success, deployment, or runtime behavior.
- If the branch head changes during inspection, stop and re-inspect rather than writing against stale state.
