Title: "make-pr: tmp branch cleanup on error + tmp-pr collision detection"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "—"
Created-By: "Laforge"
Created: "2026-10-01T10:42:26Z"
Doc-Ref: "—"

Fix two gaps in xx-make-pr: (1) No cleanup of tmp branch on error - 6 return paths without defer/branch -D. (2) tmp-pr name collision not detected - if 'tmp-pr' branch exists, 'git checkout -b tmp-pr/...' fails with cryptic 'cannot lock ref' error instead of clear message.

- 2026-10-01T10:42:38Z Laforge: progress 10% (Starting fix: two gaps identified in xxmakepr.go - (1) tmp branch cleanup on error using defer, (2) tmp-pr collision detection before checkout)

- 2026-10-01T11:16:56Z Laforge: progress 100% (Both fixes implemented and verified:
1. tmp branch cleanup on error: Added defer cleanup that switches back to incubatorBranch and deletes tmpBranch on any error path
2. tmp-pr collision detection: Added hasBranchPrefixCollision() that detects git D/F conflicts (exact match and prefix collisions like foo vs foo/bar) before git checkout, providing clear error message instead of cryptic 'cannot lock ref'

Both verified:
- tmp branch cleaned up after cherry-pick failure (switched back to incubatorBranch, deleted tmpBranch)
- Collision detection works: clear error 'cannot create temporary branch... due to git D/F conflict' instead of cryptic 'cannot lock ref'
)

- 2026-10-01T11:37:50Z Laforge: progress 100% (Collision detection implemented and verified (cleanup removed per maintainer intent):

1. tmp-pr collision detection: Added hasBranchPrefixCollision() that detects git D/F conflicts (exact match + prefix collisions like foo vs foo/bar) before git checkout, providing clear error message instead of cryptic 'cannot lock ref'

2. Cleanup behavior: Kept as intentional - no cleanup on error paths (per maintainer: failed run leaves tmp branch for manual recovery). Added comment explaining intentional behavior.

Verified:
- Collision detection works: clear error 'cannot create temporary branch... due to git D/F conflict' when conflicting branch exists (e.g., tmp-pr/existing-conflict)
- No cleanup on error: tmp branch left behind after cherry-pick failure for manual recovery
- No cleanup on success: tmp branch renamed to PR branch name (git branch -M)
)
