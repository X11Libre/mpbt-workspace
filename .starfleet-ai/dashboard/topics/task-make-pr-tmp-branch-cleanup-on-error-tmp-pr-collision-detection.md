Title: "make-pr: tmp branch cleanup on error + tmp-pr collision detection"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-10-01T10:42:26Z"
Doc-Ref: "—"

Fix two gaps in xx-make-pr: (1) No cleanup of tmp branch on error - 6 return paths without defer/branch -D. (2) tmp-pr name collision not detected - if 'tmp-pr' branch exists, 'git checkout -b tmp-pr/...' fails with cryptic 'cannot lock ref' error instead of clear message.

- 2026-10-01T10:42:38Z Laforge: progress 10% (Starting fix: two gaps identified in xxmakepr.go - (1) tmp branch cleanup on error using defer, (2) tmp-pr collision detection before checkout)
