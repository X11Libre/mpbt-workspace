---
slug: skills-claude-skills
title: "Skills (`.claude/skills/`)"
order: 50
---

## Skills (`.claude/skills/`)

Checked-in Claude Code skills wrap the recurring multi-step workflows below as on-demand
slash commands / auto-triggered procedures. They're the *actionable checklist*; the prose
sections here remain the full reference. Keep them in sync when a workflow changes.

| skill | invoke | wraps |
|-------|--------|-------|
| `backport` | `/backport` | **Backport workflow** — applicability check → `backport-commit` → cross-link |
| `pr-repair` | `/pr-repair` | **PR repair workflow** — `pr-job-logs` → `pr-checkout` → local verify → `pr-amend-push` |
| `bot-review` | `/bot-review` | **Automated reviews** — bot banner, backport-worthiness, NVIDIA-ABI check, label (named `bot-review` to avoid the built-in `/review`) |
