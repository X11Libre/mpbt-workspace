# ChatGPT workspace guidance

This directory contains project context and skills intended for ChatGPT.

It is deliberately separate from Starfleet/OpenCode configuration:

- `project.md` contains the shared workspace context and standing rules for ChatGPT.
- `skills/<skill-name>/SKILL.md` contains one focused, reusable ChatGPT workflow.
- Starfleetctl's installed skills and OpenCode/Claude configuration remain owned by Starfleetctl and are not mirrored here.

## Format

Each skill uses the Agent Skills-style directory layout and YAML frontmatter:

```yaml
---
name: skill-name
description: When this skill should be used.
---
```

Keep skills focused and procedural. Put cross-cutting rules in `project.md`, not in every skill.

## Loading

Committing a file here does not automatically load it into a ChatGPT conversation. Provide `project.md` and the relevant skill files as project instructions/files or attach them when starting the corresponding work. Do not assume ChatGPT can read the local workspace or execute its local commands.

## Scope

The initial skills cover MPBT workspace use, Xserver development, GitHub PR review, Git workflows, and Wormhole communication. Add a skill only when it describes a repeatable ChatGPT workflow that is not already owned by Starfleetctl.
