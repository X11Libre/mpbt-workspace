Title: "pasteur: permission-ask abort bug on denied filesystem access"
Category: starfleet
Kind: task
Status: "done"
Created-By: "Enterprise"
Created: "2026-08-04T08:08:45Z"
Assigned-To: "Enterprise"
Doc-Ref: "starfleetctl@a6880a3"
Slug: starfleet/task-pasteur-permission-ask-abort-bug-on-denied-filesystem-access

## Problem

Ship pasteur got stuck in permission-ask trying to access `/.starfleet-ai/...`
at root level (doesn't exist; agent built a root-absolute path from a
workspace-relative one). After deny, it aborted the entire task instead of
continuing. Background/auto ships have nobody at the console to answer a
permission prompt → the ask hangs forever, then the deny is fatal.

## Root cause

- opencode's `external_directory` permission defaults to **ask** and fires for
  ANY path outside the project working directory.
- `generateOpencodeConfig()` never emitted an `external_directory` rule, so the
  ask hit every ship (worst on detached background/auto launches).
- Confirmed in opencode.log run=bb75fa1f (2026-08-03T23:19:50Z):
  `evaluated permission=external_directory pattern=/.starfleet-ai/dashboard/topics/* action.action=ask`.

## Fix (starfleetctl master a6880a3)

- `internal/session/launch.go` `generateOpencodeConfig()` now pins
  `external_directory`:
  - background/auto ships → `"**": "deny"` (workspace + `~/.local/bin` still
    allowed) — tool call fails fast, no hang, agent can retry with a
    workspace-relative path.
  - terminal ships → `"**": "ask"` (human present).
  - unrestricted → `"**": "allow"`.
- `fragments/starfleet-instructions/working-practices-for-ships.md`: added rule
  "Never abort a task because a file access was denied" — retry with a
  workspace-relative path, use `starfleetctl` commands for dashboard/session
  data, then continue and report.
- New test `internal/session/launch_test.go`
  `TestGenerateOpencodeConfigExternalDirectory` (background/auto deny,
  terminal ask, unrestricted allow). `make all` green.

## Deployment

- Commits a3b738d (leftover plugin v2.6.0) + a6880a3 pushed to master.
- `./starfleet-bootstrap` → reindexed sop.d/index.md (new rule present),
  web restart → HTTP 200 on :8080, timer worker restarted.
- Takes effect at next ship launch (per-ship config is generated at launch;
  running ships keep their old config in memory). pasteur should be restarted
  (`session restart pasteur`) to pick it up.
