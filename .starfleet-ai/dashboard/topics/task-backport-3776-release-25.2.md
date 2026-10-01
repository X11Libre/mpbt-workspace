---
slug: task-backport-3776-release-25.2
title: "Backport #3776: Xi: byte-swap XIQueryDevice ScrollClass flags to release/25.2"
status: active
category: task
assigned_to: Galaxy
tags: ["backport", "xi", "scrollclass", "release/25.2"]
doc_ref: "https://github.com/X11Libre/xserver/pull/3801"
---

## Backport #3776 to release/25.2

**Original PR:** #3776 (master)
**Backport PR:** #3801
**Target branch:** release/25.2
**Commit SHA:** 5099dc545 (cherry-picked from 9f1a06d0b535af2d26c2d684196f33e02a914a60)

### Changes
- `Xext/xinput/xiquerydevice.c`: Added `swapl(&info->flags);` in `SwapScrollInfo()`
- `test/xi2/protocol-xiquerydevice.c`: Added `swapl(&si->flags);` in swapped reply handling

### Notes
Files on release/25.2 are at the same paths as master (Xext/xinput/...). No path rewrite needed.

### Acceptance Criteria
- [ ] PR #3801 passes CI
- [ ] Reviewed and approved
- [ ] Merged by maintainer (manual merge, rebase mode)

Part of batch: task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0
