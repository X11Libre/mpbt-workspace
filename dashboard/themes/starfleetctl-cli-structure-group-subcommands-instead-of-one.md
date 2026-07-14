---
slug: starfleetctl-cli-structure-group-subcommands-instead-of-one
title: "`starfleetctl` CLI structure: group subcommands instead of one flat namespace"
category: parked
noted_by: "praetor, 2026-07-06"
since: "2026-07-06"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

With 11+ subcommands already (and Phase 2's mutating pr-* subset about to add ~9 more), `starfleetctl <name>` is becoming a flat, undifferentiated list. Idea: split into subcommand **groups** — e.g. pure fleet-coordination (`agent-bus`, `pr-claim`, `ws-commit`, `ship-names`, `with-clone-lock`, `dashboard`) under one group, GitHub-interaction (`pr-view`, `pr-ci`, `show-branch-file`, `backport-applies`, `show-pr-conflict`, and the Phase-2 mutating set) under another — something like `starfleetctl fleet <cmd>` vs `starfleetctl gh <cmd>` (exact names TBD). Explicitly a **later** consideration, not urgent — do not restructure the CLI surface while Phase 2's cutover and the README (m0061) are still in flight, since that would churn the exact commands/docs being written right now. Revisit once the current subcommand set stabilizes; would need a compatibility thought (keep flat aliases during transition, or a clean breaking change since every caller is internal to this workspace anyway — no external consumers to preserve compat for).
