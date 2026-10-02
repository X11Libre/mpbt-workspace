---
title: "Backport #3775 (Xi: byte-swap DeviceChanged valuator) auf release/25.2, 25.1, 25.0"
category: active
kind: task
status: "done"
created_by: "Enterprise"
created: "2026-10-02T10:09:42Z"
assigned_to: "Pasteur"
doc_ref: "—"
slug: task-backport-3775-xi-byte-swap-devicechanged-valuator-auf-release-25-2-25-1-25-0
---

# Backport #3775 (Xi: byte-swap DeviceChanged valuator) auf release/25.2, 25.1, 25.0

## Status: DONE

### PRs Created
- **25.2**: PR #3823 (branch: backport/3775-to-25.2) - files: Xext/xinput/extinit.c, test/xi2/protocol-eventconvert.c
- **25.1**: PR #3824 (branch: backport/3775-to-25.1) - files: Xi/extinit.c, test/xi2/protocol-eventconvert.c
- **25.0**: PR #3825 (branch: backport/3775-to-25.0) - files: Xi/extinit.c, test/xi2/protocol-eventconvert.c

### Verification
- Source commit: cafe531326b9b387e4fe6098cf12f4210b13d03f (PR #3775 merge commit)
- All have exactly 1 sign-off (Lukáš Lipinský)
- rev-list count = 1 (only our cherry-pick)
- Paths match specification: 25.2 uses Xext/xinput/extinit.c, 25.1/25.0 use Xi/extinit.c
- CI will run on each PR

### Commits
- 25.2: ca7c9985f6
- 25.1: adcb6ce0f9
- 25.0: 87d7611e3f
