# XLibre MPBT workspace — ChatGPT project context

## Purpose and layout

This repository is the MPBT workspace for building XLibre's Xserver and related drivers across release lines.

- `cf/` is the configuration source of truth: package definitions, templates, per-release settings, and build solutions.
- `run-fetch.*` and `run-build.*` are the workspace's release-specific fetch/build entry points.
- `scripts/` contains workspace helper tools.
- `_WORK_/` contains local clones, worktrees, build directories, and install prefixes. It is generated/local state and is gitignored.
- `.starfleet-ai/` is the workspace-local Starfleetctl deployment/runtime area.
- `.opencode/` and `.claude/` contain agent-tool configuration and installed assets.

Read the current `README.md` and relevant `cf/<release>/` files before making release-specific recommendations. Do not infer a release from the existence of similarly named scripts.

## Separation of responsibilities

- This directory (`.chatgpt/`) is for ChatGPT context and ChatGPT-specific skills only.
- Starfleetctl remains the source of truth for Starfleet/OpenCode/Claude skills and their installation. Do not create a parallel Starfleet skill hierarchy or modify its skill deployment as part of ChatGPT work.
- Wormhole is a communication transport between ChatGPT and Starfleet ships, not a repository for ChatGPT configuration.
- Keep project rules/context separate from task-specific skills.

## ChatGPT capability boundary

ChatGPT does not have direct access to this machine's local clones, shell, running Starfleet processes, or OpenCode sessions. It may inspect and modify GitHub repository content through an available GitHub connection, and it may communicate with Starfleet through the documented Wormhole path when that is available.

Never claim that a local command ran, a ship is active, a message was imported, or a session received a message unless there is direct evidence. A GitHub commit proves publication only; it does not prove Wormhole pickup, session delivery, or agent execution.

When local execution is required, provide a concise command or ask the user to run it. Do not fabricate command output.

## Branch and change discipline

- ChatGPT-owned workspace configuration belongs on `X11Libre/mpbt-workspace:mtx/agent-config` unless the user explicitly selects another branch.
- Do not write ChatGPT configuration to `master`.
- Before any GitHub write, inspect the current branch head and the target file/tree. Refuse to write against a stale head or stale file SHA.
- Keep changes narrowly scoped and commits focused. Separate unrelated fixes into separate commits.
- Do not merge, rebase, force-push, delete branches, or alter unrelated files unless explicitly requested.
- Do not infer that a branch is clean from its last commit message; inspect the actual tree/diff where possible.

## Shared workspace safety

The MPBT-managed source clones under `_WORK_/<solution>/sources/` are shared. Do not write, stage, commit, or switch branches in those shared source clones. Use a dedicated worktree or private clone for source changes, following the current README and Starfleetctl workflow.

Treat `_WORK_/` as disposable/generated workspace state. Persistent project documentation and configuration belong in tracked locations.

## Collaboration and response style

- Preserve the user's explicit scope and existing design decisions.
- Prefer minimal, reviewable changes over broad cleanup or reformatting.
- Distinguish observed facts, inferred explanations, and unverified assumptions.
- Report exact repository, branch, commit, paths, and verification evidence for changes.
- Communicate in German unless the user asks otherwise; do not use German gender-inclusive spellings.
