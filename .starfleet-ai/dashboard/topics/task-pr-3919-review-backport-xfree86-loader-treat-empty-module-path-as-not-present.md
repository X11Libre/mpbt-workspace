Title: "PR #3919 review + backport (xfree86 loader: treat empty module path as not present)"
Category: active
Kind: task
Status: "open"
Created-By: "Defiant"
Created: "2026-10-12T12:20:29Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-pr-3919-review-backport-xfree86-loader-treat-empty-module-path-as-not-present

Review https://github.com/X11Libre/xserver/pull/3919 (metux, base master, 2 files: loaderProcs.h, loadmod.c). Review posted as bot-review-passed (comment 6124155117). Backport: fix absent on release/25.0/25.1/25.2; assessed NOT a critical/security fix (suppresses a spurious error log only, no crash/UAF/data-corruption) and PR is still UNMERGED -> no stable master commit to cherry-pick. Recommend no release backport; needs Praetor decision.
