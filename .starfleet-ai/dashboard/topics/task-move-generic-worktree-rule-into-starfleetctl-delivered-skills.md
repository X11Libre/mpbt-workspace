Title: "Move generic worktree rule into starfleetctl-delivered skills"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-11T13:48:28Z"
Assigned-To: "Scotty"
Doc-Ref: "—"
Slug: task-move-generic-worktree-rule-into-starfleetctl-delivered-skills

Workspace commit 7de3c34817 has sharpened the worktree guidance in the workspace-local skill copies (starfleet-sessions SKILL.md, branch-hygiene reference.md, go-x11proto reference.md): ALWAYS use 'starfleetctl worktree add/list/remove/prune', never bare 'git worktree', even on mpbt-cloned sources under _WORK_/. The starfleet-generic part of this (the rule itself + the worktree command table with --from/--branch/--keep-branch semantics) needs to be promoted into the starfleetctl-repo skill sources under fragments/starfleet-skills/starfleet-sessions/SKILL.md (and any other starfleet-* skill that mentions worktrees), then committed in the starfleetctl repo and rolled out via ./starfleet-bootstrap. WORKSPACE-LOCAL parts that must NOT be copied: the go-x11proto re-dock note (project-specific), the branch-hygiene zipper-rebase workflow (project-specific). Reviewed-by Enterprise.
