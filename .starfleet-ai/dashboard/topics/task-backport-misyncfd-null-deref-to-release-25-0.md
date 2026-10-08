Title: "Backport #3647 misyncfd NULL-deref fix to release/25.0"
Category: active
Kind: task
Status: "assigned"
Created-By: "XL-0"
Created: "2026-10-08T09:03:30Z"
Assigned-To: "XL-0"
Doc-Ref: "—"
Slug: task-backport-misyncfd-null-deref-to-release-25-0

Lost backport: PR #3675 (head pr/release/25.0-miext-sync-...) was closed 2026-09-15 unmerged; fix is NOT on release/25.0 (measured via git log --grep). Source: master PR #3647, merged as 950ed3f56c2b6561c2ffcf193b9fa1fb460c4e68 (issue #3629, multi-GPU crash on XSyncCreateFenceFromFD with NVIDIA blob under PRIME). Work in own worktree, branch rfc/backport-25.0-misyncfd, verify build, open PR against release/25.0, report to Enterprise.
