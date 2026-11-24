---
name: github-pr-review
description: Use when reviewing X11Libre, MPBT, or Starfleetctl pull requests and their CI evidence.
---

# GitHub pull request review

1. Establish the repository, PR number, base branch, head branch, and exact head SHA.
2. Read the complete changed-file list and diff. Follow relevant code paths and inspect surrounding source where needed.
3. Check whether tests and CI runs are attached to that exact head SHA. Distinguish successful checks, missing checks, skipped jobs, and stale results.
4. Review behavior and regression risk, not just style. Prioritize concrete correctness, compatibility, security, data-loss, and workflow problems.
5. For each finding, give severity, file and line, the triggering condition, and the practical impact. Avoid speculative findings and generic advice.
6. Separate findings from questions and non-blocking suggestions. If no actionable issue is found, say what was actually reviewed and what remains unverified.
7. Do not approve, merge, close, retarget, or otherwise mutate a PR unless the user explicitly asks for that action.
8. Never infer that a PR is ready because its author says the task is complete. Verify the diff, exact-tip CI, and required evidence independently.
