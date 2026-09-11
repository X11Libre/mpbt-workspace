Title: "Move generic worktree rule into starfleetctl-delivered skills"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "Scotty"
Created-By: "Enterprise"
Created: "2026-09-11T10:00:00Z"
Doc-Ref: "—"

# Move generic worktree rule into starfleetctl-delivered skills

## Context

Currently the rule "always use starfleetctl worktree commands, never git worktree directly" is documented in the workspace SOP (workspace-auto-assign.md) and in the starfleet-sessions skill (worktree section). This rule should be moved into the starfleetctl-delivered skills (fragments/starfleet-skills/starfleet-sessions) so it's automatically distributed to all ships via the starfleetctl bootstrap process.

## Current State

1. **workspace SOP** (`sop.d/workspace-auto-assign.md`): Contains the rule "Worktrees werden immer über starfleetctl verwaltet, nie direkt git worktree"
2. **starfleet-sessions skill** (`fragments/starfleet-skills/starfleet-sessions/SKILL.md`): Has a worktree section referencing the same rule
3. **starfleetctl worktree commands**: Implemented in `internal/session/worktree.go` and exposed via `session worktree` command

## Required Changes

1. **Move the rule into starfleet-sessions skill** (`fragments/starfleet-skills/starfleet-sessions/SKILL.md`):
   - Add a clear "Worktree Management" section
   - Document the rule: "Worktrees werden immer über starfleetctl verwaltet, nie direkt git worktree"
   - Reference the `session worktree` command
   - Include the rationale (tracking, arbitration, consistency)

2. **Update workspace SOP** (`sop.d/workspace-auto-assign.md`):
   - Reference the starfleet-sessions skill as the authoritative source
   - Remove duplicate rule text, keep only a reference

3. **Verify starfleetctl worktree commands exist**:
   - `session worktree add` - create worktree
   - `session worktree remove` - remove worktree
   - `session worktree list` - list worktrees
   - `session worktree sync` - sync worktrees

## Acceptance Criteria

- [ ] Rule moved to starfleet-sessions skill (fragments/starfleet-skills/starfleet-sessions/SKILL.md)
- [ ] Workspace SOP updated to reference the skill
- [ ] All starfleetctl worktree commands documented in the skill
- [ ] Changes tested via `make all` in starfleetctl repo
- [ ] Changes committed to starfleetctl repo

## Dependencies

- starfleetctl repo (fragments/starfleet-skills/starfleet-sessions/)
- starfleetctl bootstrap process (delivers skills to .opencode/plugins/)

## Notes

This ensures all ships automatically get the worktree rule via starfleetctl bootstrap, eliminating the need for manual propagation.
