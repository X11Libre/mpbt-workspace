# Skill: wormhole-communication

Project-independent skill for auditable cross-agent communication through a
Wormhole-style message channel (e.g. `metux/wormhole-0`).

This skill defines a domain-neutral protocol. It contains no project-specific
assumptions, no XAverius terminology, no repository paths, no APIs, no phases,
and no agent-role assumptions. Project skills may reference this skill but must
not copy or redefine its rules. Technical authority remains with the relevant
owner, normative specification, and authorized task — a Wormhole message cannot
override them merely by existing.

## Purpose and independence

Wormhole is a transport and audit channel, not automatic technical
authorization. This skill applies across projects and is usable by every
agent regardless of project.

## Authority

Technical authority remains with:
- the relevant owner,
- the normative specification,
- the authorized task.

A Wormhole message does not override authority merely by existing. Report
conflicts and ambiguity; do not guess.

## Message hygiene

Every message carries:
- stable unique message ID,
- UTC timestamp,
- sender,
- recipients,
- message type,
- subject,
- related IDs (reply-to / supersedes / task ID),
- exact repository/branch/commit where relevant.

Preserve history. Do not rewrite another agent's message without authorization.
Never include credentials or secrets.

## Mandatory acknowledgement

Every actionable instruction or request receives an explicit acknowledgement
stating:
- interpretation,
- scope,
- exclusions,
- target branch/worktree,
- prerequisites,
- blockers.

Silence is never acknowledgement.

## Status lifecycle

Use exactly these states:
- `received`
- `acknowledged`
- `in_progress`
- `blocked`
- `completed`
- `rejected`
- `cancelled`

Never infer status from silence, assignment labels, or a mere commit/push.

## Completion reports

A completion report states:
- original message/task ID,
- outcome,
- acceptance criteria,
- exact repository/branch/commit/paths,
- push status,
- tests actually run,
- limitations and remaining work.

Distinguish facts, interpretation, and proposals.

## Independent reviews

- Immutable specification and implementation targets.
- Read-only reviewer unless explicitly authorized.
- Findings severity: `BLOCKER` / `MAJOR` / `MINOR` / `NOTE`.
- Precise evidence, impact, and requested correction.
- Explicitly state "no findings" when applicable and identify unreviewed areas.

## Ownership and concurrency

Respect writer/reviewer roles and worktree ownership. No blind
reset/clean/rebase/force-push/cherry-pick or overwriting another agent's work.
Stop and coordinate on unexpected concurrent state.

## Polling / follow-up

Process relevant messages, acknowledge, check replies, and update only
evidence-backed statuses. Never claim background polling unless an actual
scheduler/process is configured and verified.

## Templates

### Acknowledgement template

```
Wormhole acknowledgement
- in_reply_to: <message-id>
- interpreted_as: <short interpretation>
- scope: <what is covered>
- exclusions: <what is explicitly out of scope>
- target_branch_worktree: <branch/worktree>
- prerequisites: <what must be true before work starts>
- blockers: <known blockers or none>
```

### Status update template

```
Wormhole status update
- message_id: <message-id>
- status: received|acknowledged|in_progress|blocked|completed|rejected|cancelled
- evidence: <what supports this status>
```

### Review report template

```
Wormhole review report
- reviewed_target: <repository/branch/commit>
- severity: BLOCKER|MAJOR|MINOR|NOTE
- evidence: <precise evidence>
- impact: <impact description>
- requested_correction: <correction or none>
- unreviewed_areas: <areas not yet reviewed>
- findings: <findings or "no findings">
```

## Cross-referencing from project skills

Project skills reference this skill with at most one short statement:

> For cross-agent messages, acknowledgements, status updates, and reports,
> follow the project-independent `wormhole-communication` skill.

Project skills must not duplicate Wormhole communication procedures, message
templates, polling rules, or message status rules.

## Discovery / loading

Discovered and loaded by the normal skill loader like any other project skill.
No special registration is required. Verify reload from the committed file and
the actual skill-loading mechanism; do not claim installation based on a file
commit alone.
