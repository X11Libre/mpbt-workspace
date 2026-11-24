---
name: mpbt-workflow
description: Use when navigating, fetching, configuring, or building projects in the XLibre MPBT workspace.
---

# MPBT workspace workflow

1. Read the workspace `README.md` and the relevant `cf/<release>/config.sh` and solution file before discussing or changing a release workflow.
2. Identify the exact release line. The workspace keeps release configurations and work areas separate; never assume that `xserver-master` and a numbered release use the same build options.
3. Use the matching `run-fetch.<solution>` and `run-build.<solution>` entry points when describing the normal workspace workflow. Check the current scripts before relying on their behavior.
4. Treat `cf/` as tracked configuration and `_WORK_/` as local/generated state. Do not put persistent instructions or project decisions under `_WORK_/`.
5. The MPBT-managed source clones under `_WORK_/<solution>/sources/` are shared. Do not edit, stage, commit, or switch branches in them. Use a dedicated worktree or private clone for source changes, following the workspace README and Starfleetctl workflow.
6. Remember that a build may remove its install prefix after completion; check the current `run-build.*` script before assuming artifacts remain available.
7. ChatGPT cannot execute the local MPBT commands or inspect local build output unless the user supplies it. Provide exact commands and clearly label unverified outcomes rather than claiming execution.
