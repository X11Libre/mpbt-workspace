Title: "Backport #3647 misyncfd NULL-deref fix to release/25.0"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "XL-0"
Created-By: "XL-0"
Created: "2026-10-08T09:03:30Z"
Doc-Ref: "—"

Lost backport: PR #3675 (head pr/release/25.0-miext-sync-...) was closed 2026-09-15 unmerged; fix is NOT on release/25.0 (measured via git log --grep). Source: master PR #3647, merged as 950ed3f56c2b6561c2ffcf193b9fa1fb460c4e68 (issue #3629, multi-GPU crash on XSyncCreateFenceFromFD with NVIDIA blob under PRIME). Work in own worktree, branch rfc/backport-25.0-misyncfd, verify build, open PR against release/25.0, report to Enterprise.

- 2026-10-08T09:16:19Z XL-0: completed

- 2026-10-08T09:51:01Z XL-0: KORREKTUR/EINGESTELLT: Backport ist N-A fuer release/25.0. PR #3866 geschlossen. Beweis: (1) prerequisite 852128f18 (Prealloc via sizeof) NICHT auf release/25.0 (merge-base exit 1); Cherry-Pick dereferenziert NULL -> A/B lokal: mit Patch Segfault 0x10 in xehypr-glamor-Test (Signatur identisch zu CI), ohne Patch OK. (2) Bug kann auf 25.0 nicht auftreten (uninitialisierte Screens liefern NULL, guards greifen). (3) metux schloss Original-PR #3675 am 15.09.: 'isn't needed / relevant for release branches'.
