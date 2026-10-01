Title: "make-pr: tmp branch cleanup on error + tmp-pr collision detection"
Category: active
Kind: task
Status: "open"
Created-By: "Laforge"
Created: "2026-10-01T10:42:26Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-make-pr-tmp-branch-cleanup-on-error-tmp-pr-collision-detection

Fix two gaps in xx-make-pr: (1) No cleanup of tmp branch on error - 6 return paths without defer/branch -D. (2) tmp-pr name collision not detected - if 'tmp-pr' branch exists, 'git checkout -b tmp-pr/...' fails with cryptic 'cannot lock ref' error instead of clear message.
