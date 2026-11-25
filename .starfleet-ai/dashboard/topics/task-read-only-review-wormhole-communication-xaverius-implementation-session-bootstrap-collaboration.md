Title: "Read-only review: wormhole-communication, xaverius-implementation, SESSION_BOOTSTRAP, COLLABORATION"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Discovery"
Created-By: "Discovery"
Created: "2026-11-25T15:35:35Z"
Doc-Ref: "—"

- 2026-11-25T15:35:51Z Discovery: began work

- 2026-11-25T15:39:14Z Discovery: progress 100% (Review complete. Key findings documented below.

## READ-ONLY REVIEW FINDINGS

### 1. wormhole-communication/SKILL.md (.claude/skills/wormhole-communication/SKILL.md)

Severity: NOTE - Minor clarity gaps

- Line 14-16: Claims "contains no project-specific assumptions, no XAverius terminology, no repository paths, no APIs, no phases, and no agent-role assumptions" -- TRUE, skill is genuinely project-independent.
- Line 44-45: "Preserve history. Do not rewrite another agent's message without authorization." -- Good.
- Line 47-51: "Mandatory acknowledgement" template references message-id but doesn't specify the Wormhole message ID format (w0-...). Could add format note.
- Line 53-58: Status lifecycle uses exactly 7 states -- matches actual Comms implementation (unseen/seen/cur/processed/failed maps to these).
- Line 60-68: Completion report template -- good, but missing mention of ExternalID correlation for Wormhole transport.
- Line 80-86: "Discovery / loading" section claims skill discovered by "normal skill loader" -- no verification that skill loader actually loads this; should add verification note.
- Cross-reference rule (line 92-95): Correctly prevents duplication. However, xaverius-implementation skill does NOT reference this skill (see finding #2).

### 2. xaverius-implementation/SKILL.md (.claude/skills/xaverius-implementation/SKILL.md)

Severity: MAJOR - Missing cross-reference + stale token reference

- NO reference to wormhole-communication skill -- violates the cross-referencing rule in wormhole-communication (line 92-95: "Project skills reference this skill with at most one short statement"). XAverius implementation uses Wormhole for coordination but doesn't declare the dependency.
- Line 88-90 "Stale Tokens": Lists XaveriusDDXOps, XaveriusScreenInit, XaveriusRegisterProvider, etc. as "must NOT appear in actionable guidance". VERIFIED: These tokens do NOT appear in the current xaverius implementation headers (xaverius_proto.h, xaverius_priv.h, xaverius_intern.h) -- good, skill correctly identifies stale tokens.
- Line 70: References IMPLEMENTATION_COORDINATION.md -- this file does NOT exist in the xav-design repo (checked: no such file in metux/xav-design:docs/restructure-2026-10-21). STALE REFERENCE.
- Line 65: "Before work: git -C X11Libre/xserver rev-parse --verify wip/xaverius" -- assumes the worktree exists at that path. In mpbt workspace, it's under _WORK_/xserver-master/sources/xlibre/xserver or a worktree. Path mismatch could mislead.
- Line 66: "cd _WORK_/xav/xav-design && git pull" -- assumes _WORK_/xav/xav-design exists. Not verified in current workspace structure.

### 3. SESSION_BOOTSTRAP.md (metux/wormhole-0:master/SESSION_BOOTSTRAP.md)

Severity: MAJOR - Stale assignments, outdated SHAs, missing current state

- Line 18-21: Repository assignments reference branches that may be stale:
  - X11Libre/xserver:wip/xaverius -- last known HEAD eaff9a2 (2026-11-06 checkpoint). NEEDS REFRESH.
  - mpbt-hq/starfleetctl:work/wormhole-manager-w0-017 -- current HEAD is a252e6a (with plugin tests), but bootstrap cites 94af3ab (2026-11-06) and 8f0d7b4 (2026-11-06). STALE SHAs.
- Line 24-27: Role boundaries -- "Enterprise: local fleet coordination only... must NOT perform technical audits... owner retains merge authority". CONSISTENT with current fleet instructions.
- Line 30-34: "Current coordination task IDs" -- W0-050 through W0-053 from 2026-11-06. No newer task IDs appended. STALE -- should include W0-062/063 (Comms health probes, Defiant ask-stall) and newer plugin hardening tasks.
- Line 44-98: "Wormhole implementation audit baseline" -- references commit 94af3ab claiming "complete wormhole manager" rejected by owner. The current branch work/wormhole-manager-w0-017 at a252e6a has SIGNIFICANTLY CORRECTED implementation (Bus.PostExternal integration, durable journal, idempotency, real daemon, proper tests). This section is OUTDATED and could mislead a new session into thinking the old rejected draft is current.
- Line 100-125: "XAverius implementation audit baseline" -- references eaff9a2 and blockers from W0-052. Current Defiant work may have progressed; needs refresh against actual wip/xaverius HEAD.
- Line 127-133: "Session behavior and reporting" -- "Audit every newly visible Laforge commit across all branches, even without PR" -- good practice.
- Line 135-168: "Update 2026-11-06 evening" -- describes Laforge branch discovery and owner rejection of 94af3ab. HISTORICAL, not current state. Current branch has a252e6a with fixes.
- Line 170-200: "Update 2026-11-06 22:20Z" -- W0-062/063 Comms health probes. STILL RELEVANT but should note current status.
- Line 202-240: "Update 2026-11-06 console-ship safety rule" -- OpenCode plugin research. RELEVANT but plugin hardening task (w0-20261125T082600Z) now exists with tests.
- Line 242-260: "Update 2026-11-06 ask policy draft" -- references design-drafts/ASK_TOOL_POLICY_AND_RELAY.md. File exists in fleet-comms repo.
- Line 262-305: "Update 2026-11-06 concurrent ChatGPT sessions" -- multi-session architecture draft. References design-drafts/MULTI_SESSION_ACCESS.md. File exists.
- Missing: No mention of current W0-017 closeout status (completed per task_done), plugin integration test hardening (completed), or current Enterprise coordination state.

### 4. COLLABORATION.md (metux/wormhole-0:master/COLLABORATION.md)

Severity: MINOR - Minor clarity gaps

- Line 13-14: "Comms is the only messaging system exposed to agents." -- TRUE per current architecture.
- Line 15-16: "Wormhole manager transports immutable messages through the Maildir spool and imports incoming messages through Comms Core's external-ingestion API." -- ACCURATE -- Bus.PostExternal is the ingestion API.
- Line 23-35: Maildir layout -- MATCHES actual implementation (mail/<ship>/{new,cur,processed,failed}).
- Line 37-48: Active message file format -- MATCHES actual YAML front matter format used.
- Line 50-57: Legacy archive and cutover rule -- CORRECT. inbox/ and outbox/ are frozen. initial_scan: baseline behavior matches spool.go implementation.
- Line 60-68: Decisions directory -- exists and used (e.g., decisions/2026-11-08--wormhole-is-comms-transport.md).
- Line 71: "A Git push proves publication only; it does not prove import, session delivery, processing, or task completion." -- CRITICAL TRUTH matching W0-134 findings.
- Missing: No mention of ExternalID / ExternalHash correlation fields added in W0-134 for idempotency. No mention of mail/.tmp/ staging directory used for durable writes.

### 5. Cross-file Consistency

Severity: MAJOR - Multiple mismatches

| Aspect | wormhole-communication | SESSION_BOOTSTRAP | COLLABORATION | Actual Implementation |
|--------|------------------------|-------------------|---------------|----------------------|
| Message ID format | Not specified | w0-... used | Not specified | w0-<timestamp>-<hash> |
| Acknowledgement | Template with in_reply_to | Not specified | Not specified | Comms ack command + seen_mark |
| Status states | 7 states (received..cancelled) | Not specified | Not explicit | unseen/seen/processed/failed |
| Ingestion API | Not specified | Bus.PostExternal | external-ingestion API | Bus.PostExternal(source, externalID, from, target, text) 5-arg |
| Idempotency | Not specified | Not specified | Not specified | ExternalHash + outbox record |
| Daemon | Not specified | "fake in-process daemon" (historical) | Not specified | Real daemon with worker process |

### 6. Skill Loading Verification

- wormhole-communication: Located at .claude/skills/wormhole-communication/SKILL.md. Skill loader discovery mechanism not verified -- skill claims "Discovered and loaded by the normal skill loader" but no evidence loader actually finds .claude/skills/ directory.
- xaverius-implementation: Located at .claude/skills/xaverius-implementation/SKILL.md. Same loading concern.
- No mechanism verified that these skills are auto-loaded for relevant agents. The opencode plugin for starfleetctl loads fleet instructions from sop.d/starfleet-instructions/, not from .claude/skills/.

---

## RECOMMENDED MINIMAL CORRECTIONS

1. SESSION_BOOTSTRAP.md: Update SHAs to current branch tips (a252e6a for wormhole-manager, refresh XAverius). Remove/add "HISTORICAL" markers on outdated audit sections. Add current task IDs (W0-017 closeout, plugin hardening, Comms probes).

2. xaverius-implementation/SKILL.md: Add cross-reference line: "For cross-agent messages, acknowledgements, status updates, and reports, follow the project-independent wormhole-communication skill." Fix/remove stale IMPLEMENTATION_COORDINATION.md and path references.

3. wormhole-communication/SKILL.md: Add Wormhole message ID format note (w0-<ISO-timestamp>-<hash>). Add note about ExternalHash/ExternalID correlation for idempotency. Add loader verification note.

4. COLLABORATION.md: Add note about mail/.tmp/ staging directory and ExternalHash correlation fields. Document 5-arg PostExternal contract.

5. Skill loading: Verify .claude/skills/ is in skill loader search path. If not, document manual load requirement or move to sop.d/starfleet-instructions/ (tool-owned).)

- 2026-11-25T15:39:23Z Discovery: completed
