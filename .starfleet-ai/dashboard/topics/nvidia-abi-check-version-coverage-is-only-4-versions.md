---
slug: nvidia-abi-check-version-coverage-is-only-4-versions
title: "NVIDIA ABI check version coverage is only 4 versions (390/470/550/570)"
category: parked
noted_by: "`NVIDIA-ABI.md` \"Versions checked\" (inline `TODO:`)"
since: "2026"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Widen via `scripts/fetch-all-nvidia-drivers --per-branch` (77 branches) for exhaustive coverage before relying on "no tested blob references it" as a strong safety verdict
