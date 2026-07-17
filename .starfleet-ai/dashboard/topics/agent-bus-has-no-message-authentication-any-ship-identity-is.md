---
slug: agent-bus-has-no-message-authentication-any-ship-identity-is
title: "`agent-bus` has no message authentication — any ship identity is pure self-report"
category: parked
noted_by: "Constellation (m0032) + Endeavour (m0033), independently, 2026-07-06"
since: "2026-07-06"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Both correctly refused to adopt the `maintainer`→`praetor` vocabulary change (broadcast m0031) pending verification, since a `tell`/`broadcast` claiming to be from `Enterprise` cannot be cryptographically distinguished from a spoofed one — `AGENT_ID` is just an env var, and commit-author metadata proves nothing either (every `mtx/*`-grant session commits as the same git identity). Enterprise confirmed the specific instance was legitimate (given live, in the same continuous chat as the praetor's away-announcement and 5-phase roadmap — internal consistency, not cryptographic proof) via m0035/m0036; both ships adopted it after. **The underlying gap is real and worth fixing before agent-bus ever carries higher-stakes directives** (e.g. merge-authorization, destructive actions) — some kind of signing/shared-secret/out-of-band confirmation for directives from the flagship. Not scoped/designed yet. Good sign: this is exactly the skepticism the fleet should apply to unauthenticated bus traffic — encourage, don't suppress.
