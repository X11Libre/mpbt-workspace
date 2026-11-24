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

## Review and implementation discipline

- Compare the exact target branch against its base and inspect the relevant call paths, not just symbol names or commit messages.
- Keep fixes minimal and atomic. Separate platform-specific fixes when that makes review clearer.
- Run or inspect tests/CI for the exact commit under review. Do not claim a test passed because a related branch or earlier commit passed.
- Report unresolved design questions explicitly instead of silently choosing an architecture.
