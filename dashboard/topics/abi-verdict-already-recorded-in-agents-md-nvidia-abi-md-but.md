---
slug: abi-verdict-already-recorded-in-agents-md-nvidia-abi-md-but
title: "ABI verdict already recorded in `AGENTS.md`/`NVIDIA-ABI.md`, but the PR itself is still open"
category: parked
noted_by: "`AGENTS.md` \"Automated reviews\" (NVIDIA-ABI section)"
since: "2026-07-01"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

PR #1786 (`Draft: drop MI overlay code` — verdict: breaks all tested blobs, deletes 6 `miOverlay*` symbols), #2070 (`unexport xf86CursorScreenKeyRec` — verdict: resolved by runtime lookup in all blobs, unsafe), #808 (`RFC: drop XvMC` — verdict: safe, no tested blob references it) all still sit open on GitHub with no label/close action taken on the verdict
