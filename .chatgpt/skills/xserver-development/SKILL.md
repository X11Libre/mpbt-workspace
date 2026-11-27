---
name: xserver-development
description: Use when planning, implementing, or reviewing XLibre Xserver and Xaverius changes.
---

# Xserver development workflow

## Establish scope first

- Identify whether the task concerns the Xserver implementation, the Xaverius specification, or both.
- If the user asks for specification work only, do not implement code.
- If implementation is requested, inspect the current specification, target branch, and exact source before proposing changes.
- Keep unrelated cleanup, formatting, renames, and refactors out of focused fixes.

## Xaverius design constraints

Treat these as existing project decisions, but verify them against the current specification and branch before changing anything:

- QueryVersion uses subopcode 0.
- There is no separate provider object model; the DDX registers physical devices directly.
- PhysicalDeviceOps is const and supplied at registration.
- The Xaverius/Xserver side allocates the physical-device XID; the driver does not allocate it.
- Avoid duplicating or overlapping the existing Xaverius capability model.
- Keep the protocol header set to the explicitly agreed three headers; do not introduce an extra `xaverius.h` without approval.
- Use the agreed `XAVERIUS_*` naming for protocol constants and the agreed `Xaverius*` type names.
- Distinguish private in-tree exported symbols from guaranteed external ABI. In-tree symbols may use the project's private-header conventions; do not promise a stable external ABI unless explicitly specified.

## Public structure ABI and allocation ownership

Before changing any public struct used by DDX drivers, trace its real allocation,
initialization, ownership, and lifetime paths in the current source and headers.
Do not infer allocation ownership merely from a public typedef or from the
absence of an in-tree driver-side allocation.

- In-tree drivers are rebuilt with the server and can be updated together.
  The compatibility risk is out-of-tree drivers, especially proprietary blobs.
- Establish whether the server/core allocates every instance through exported
  constructors, or whether a DDX can allocate, embed, copy, or provide an
  instance itself. Check all public constructors and all relevant callers.
- If the core owns allocation and returns pointers to drivers, appending fields
  at the very end can be ABI-compatible for old consumers, provided all old
  member offsets/alignment remain unchanged and the core is the only code that
  writes the new tail. Verify the actual allocation size and every access path.
- If an out-of-tree driver may allocate or embed the struct, the core must not
  access newly appended storage unless the allocation size/capacity is
  independently guaranteed. Prefer an opaque/private sidecar or accessor
  design; otherwise do not extend the struct.
- Never insert, reorder, or remove fields in a public driver-visible struct.
  A tail append is not automatically safe: prove who allocates it and who
  writes/reads the new member first.
- Binary import/string scans can identify symbol dependencies, but cannot by
  themselves prove whether a proprietary driver allocates a public struct.
  Record that limitation explicitly rather than claiming the blob is safe.

## Review and implementation discipline

- Compare the exact target branch against its base and inspect the relevant call paths, not just symbol names or commit messages.
- Keep fixes minimal and atomic. Separate platform-specific fixes when that makes review clearer.
- Run or inspect tests/CI for the exact commit under review. Do not claim a test passed because a related branch or earlier commit passed.
- Report unresolved design questions explicitly instead of silently choosing an architecture.
