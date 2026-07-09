---
title: "Skills (`.claude/skills/`)"
order: 50
---

## Skills (`.claude/skills/`)

Checked-in skills (under `.claude/skills/<name>/SKILL.md`) wrap the recurring multi-step
workflows below as on-demand slash commands / auto-triggered procedures. They are discovered by
both Claude Code **and** OpenCode (Agent Skills — `.claude/skills/` is the Claude-compatible
discovery path). Each `SKILL.md` is the *actionable checklist*; its **`reference.md`** (in the same
skill directory) holds the full prose reference. The heavy workflow docs were moved out of the
always-loaded AGENTS.md fragments into these skills to keep base context lean — load a skill only
when the workflow is actually in play. Keep `SKILL.md` + `reference.md` in sync when a workflow
changes.

| skill | invoke | wraps |
|-------|--------|-------|
| `backport` | `/backport` | Backport workflow — applicability check → `backport-commit` → cross-link (full ref: `backport/reference.md`) |
| `pr-repair` | `/pr-repair` | PR repair workflow — `pr-job-logs` → `pr-checkout` → local verify → `pr-amend-push` (full ref: `pr-repair/reference.md`) |
| `bot-review` | `/bot-review` | Automated reviews — bot banner, backport-worthiness, NVIDIA-ABI check, label (named `bot-review` to avoid the built-in `/review`; full ref: `bot-review/reference.md`) |
| `ci-platform` | `/ci-platform` | CI platform lanes — deps images, Hurd QEMU boot, RHEL/AlmaLinux, werror, NetBSD mirror (full ref: `ci-platform/reference.md`) |
| `xorg-upstream` | `/xorg-upstream` | Upstream `xorg/main` tracking via `tracking/xorg/main-on-<rel>` branches (full ref: `xorg-upstream/reference.md`) |
| `xx-make-pr` | `/xx-make-pr` | PR workflow — `xx-make-pr.sh`/`starfleetctl xx-make-pr`: git config, Signed-off-by-only, [PR #NNNN]/PR: trailer on incubator only, explicit-SHA-only, conflict recovery (full ref: `xx-make-pr/reference.md`) |
