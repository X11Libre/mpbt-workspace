Title: "Backport PR #3793 memory safety fix to release branches"
Category: active
Kind: task
Status: "assigned"
Created-By: "Laforge"
Created: "2026-10-02T09:32:38Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: task-backport-pr-3793-memory-safety-fix-to-release-branches

Backport fix for PR #3781 realloc UAF (use-after-free in damage subsystem) to release/25.0, 25.1, and 25.2. Fix is in damagestr.h and miext/damage/damage.c (pListHead -> pListDrawable, use drawable pointer instead of list head pointer to avoid realloc UAF).
