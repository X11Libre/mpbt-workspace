---
slug: arraysize-defined-9-in-tree-inconsistently-guarded
title: "`ARRAY_SIZE` defined 9× in-tree, inconsistently guarded"
category: parked
noted_by: "`include/dix.h` + 8 others (`grep -rn 'define ARRAY_SIZE'`); dix.h guarded (#3203 **merged**; no backport — Solaris not in release CI)"
since: "2026-07-01"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

Non-standard macro **some platforms provide** (illumos `<sys/sysmacros.h>`), others don't (Linux glibc userspace) → redefinition clashes. Only `pci_id_driver_map.h` + (now) `dix.h` use `#ifndef`. Look at properly: one canonical guarded def (or a dedicated cross-platform macro header), possibly a non-clashing name; **also audit the in-tree `xf86-*` drivers** (separate repos) for their own copies. Fits the MIN/MAX-dedup theme (#3142)
