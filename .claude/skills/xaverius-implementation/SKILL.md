# Skill: xaverius-implementation

Subordinate general guidance for the XAverius extension (Vulkan-like compute/presentation API over X11) in XLibre X server. The active implementation assignment and its linked instructions take precedence over this skill. The skill is subordinate general guidance, not an independent task, phase plan, API definition, or authorization.

When skill conflicts with active assignment/spec: ignore the conflicting skill text and report it. When active assignment conflicts with normative spec: stop and request clarification. Old tasks, branches, reports, examples, and remembered plans are historical unless explicitly reactivated.

## Instruction Precedence (mandatory)

1. Explicit owner decisions/current coordination decisions.
2. Normative XAverius specification at `metux/xav-design:docs/restructure-2026-10-21`.
3. Current owner-authorized active implementation assignment and its explicitly linked implementation notes (scope, stage gates, target branch, concrete work).
4. General repository instructions and installed skills.

## Current Normative Architecture Summary

- DDX directly registers every PhysicalDevice it serves; no separate Vulkan/provider inventory.
- Process-wide PhysicalDevice identity/registry is independent of X11 Screens; ScreenAttachment is separate and non-owning.
- Exact per-device `XaveriusDeviceBackendBinding` carries borrowed native handle/context and immutable typed `XaveriusDeviceBackendOps`.
- `XaveriusModuleRole` is shared module lifetime/admission/quiescence only, not a Provider object or dispatch proxy.
- The canonical API names are those in the current normative spec/active task, including `XaveriusPhysicalDevice`, `XaveriusDeviceBackendBinding`, `XaveriusDeviceBackendOps`, `XaveriusDeviceBackendRegistration`, `XaveriusModuleRole`, `XaveriusRegistryRegisterDdxDevice()`, and `XaPhysicalDevicePublish()`.

## Exactly Three Headers

| Header | Responsibility |
|--------|---------------|
| `xaverius_proto.h` | Wire protocol only — request/reply/event structs, constants, static asserts |
| `xaverius_priv.h` | DDX-facing API/types only |
| `xaverius_intern.h` | Extension-internal declarations only |

No `xaverius.h`, `xaverius_device.h`, `xaverius_registry.h`, `resource_types.h`, or other convenience/duplicate headers absent explicit owner approval. No duplicated wire defines. Preserve existing atom/symbol names absent technical necessity.

Do not authorize protocol handlers, discovery/hotplug, modesetting, ScreenAttachment integration, Compute/Memory handlers, or backend operation implementation before Stages 1–4 are reviewed and accepted.

## Implementation Hygiene

- Generic Xserver coding guidance per `coding-style-xserver` skill applies.
- Wire constants are defined only in `xaverius_proto.h`; DDX API declarations only in `xaverius_priv.h`; internal registry declarations only in `xaverius_intern.h`.
- No SProcs — xlibre macros handle swapped clients automatically; proc and sproc use the same handler.
- Preserve existing atom/symbol names absent technical necessity.
- No gratuitous renames/reformatting or broad refactors.
- Build with `-Dwerror=true`; verify focused tests pass for each corrective commit.

## Current-Revision Verification

- Before work: `git -C X11Libre/xserver rev-parse --verify wip/xaverius` and confirm HEAD matches the active task's recorded tip.
- Before each implementation block: `cd _WORK_/xav/xav-design && git pull` to confirm spec-coordination state.
- Check `IMPLEMENTATION_COORDINATION.md` for active stage gates and target branch before extending code.
- Record exact build/test commands and logs for each corrective commit; do not claim a green build without verified logs.

## Related Skills

- `coding-style-xserver` — XLibre coding style
- `wire-format` — reply wire format (rpcbuf padding done by OS layer)
- `xserver-testing` — simple-xinit for testing

## Stale Tokens (must NOT appear in actionable guidance)

XaveriusDDXOps, XaveriusScreenInit, XaveriusRegisterProvider, XaveriusRegisterDeviceDirect, XaveriusProviderCapabilities, XaveriusProviderOps, provider_handle, XaveriusPhysicalDeviceOps, xaverius.h, xaverius_device.h, xaverius_registry.h, resource_types.h, xaverius_model.c, xaverius_inventory, old subopcode phase tables, per-Screen device registration, Provider APIs, Compute/Memory handler authorization before Stages 1–4 acceptance.

If any of these appear in actionable form in this skill, report it and do not follow that text.
