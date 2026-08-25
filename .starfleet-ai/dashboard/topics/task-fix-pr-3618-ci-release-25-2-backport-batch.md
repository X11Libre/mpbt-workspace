Title: "Fix PR #3618 CI (release/25.2 backport batch)"
Category: active
Kind: task
Status: "open"
Created-By: "Discovery"
Created: "2026-08-25T09:26:01Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-fix-pr-3618-ci-release-25-2-backport-batch

Only real CI failure was modesetting symbol test (libglamoregl.so: undefined xorgGlxCreateVendor) — stale base e0aee883ee; glx/glamor linking fixes (c5e45ea3b1, ce44514d3d, a2acca2cdc) landed on release/25.2 afterwards. Other 4 failures infra (dragonfly vmactions, 2x deps cache-miss, transient signoff API perms). Fix: rebased 16 commits onto c281632a32 (dropped already-merged dup [PR #3092]), restored lost Signed-off-by on #3561 commit, force-pushed tmp-pr/release/25.2 = 90f4325d7d. Local verify: build OK, symbol test passes; other local fails reproduce on pristine base (environmental). Status: pushed, CI poll timer active.
