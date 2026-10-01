---
slug: task-backport-3776-release-25.1
title: "Backport #3776: Xi: byte-swap XIQueryDevice ScrollClass flags to release/25.1"
status: active
category: task
assigned_to: Galaxy
tags: ["backport", "xi", "scrollclass", "release/25.1"]
doc_ref: "https://github.com/X11Libre/xserver/pull/3802"
---

## Backport #3776 to release/25.1

**Original PR:** #3776 (master)
**Backport PR:** #3802
**Target branch:** release/25.1
**Commit SHA:** 4fc06f149 (cherry-picked from 9f1a06d0b535af2d26c2d684196f33e02a914a60)

### Changes
- `Xi/xiquerydevice.c`: Added `swapl(&info->flags);` in `SwapScrollInfo()` (note: path differs from master's Xext/xinput/xiquerydevice.c)
- `test/xi2/protocol-xiquerydevice.c`: Added `swapl(&si->flags);` in swapped reply handling

### Notes
On release/25.1 (and 25.0), the file is located at `Xi/xiquerydevice.c` instead of `Xext/xinput/xiquerydevice.c`. The fix is identical.

### Acceptance Criteria
- [ ] PR #3802 passes CI
- [ ] Reviewed and approved
- [ ] Merged by maintainer (manual merge, rebase mode)

Part of batch: task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0
