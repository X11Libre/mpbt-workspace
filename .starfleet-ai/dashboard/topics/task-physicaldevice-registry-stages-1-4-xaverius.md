Title: "PhysicalDevice Registry Stages 1-4 (Xaverius)"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Defiant"
Created-By: "Enterprise"
Created: "2026-11-06T11:15:22Z"
Doc-Ref: "—"

Implement PhysicalDevice registry Stages 1-4 per active task active-physical-device-registry-task-2026-11-05.md + W0-20261105-003 handoff, with W0-20261106-002/-003/-004/-005/-008/-010/-011/-012 as corrective addenda. Three agreed headers: xaverius_proto.h (wire only), xaverius_priv.h (DDX-facing API/types), xaverius_intern.h (internal declarations). Xaverius* model: XaveriusPhysicalDevice, XaveriusDeviceBackendBinding, XaveriusDeviceBackendOps, XaveriusDeviceBackendRegistration, XaveriusModuleRole. Direct DDX PhysicalDevice registration via XaveriusRegistryRegisterDdxDevice(). No Provider API, no per-Screen device registration, no protocol handler implementation before Stage 1-4 acceptance. Branch: X11Libre/xserver:wip/xaverius

Namespace correction note (W0-20261106-012/W0-20261106-014): the canonical API namespace is Xaverius* / XAVERIUS_*, not Gpu* / GPU_*. Stage-1 commit 197f1f4311 implements this reconciliation; the historical dashboard entry below retains the names used at that commit. Stage 1 must be reconciled before proceeding to Stage 2.

- 2026-11-06T11:19:23Z Defiant: began work

- 2026-11-06T11:22:37Z Defiant: progress 25% (C5/C7 fix: canonical PhysicalDevice DIX resource type via CreateNewResourceType + destructor, RegistryInit returns bool, Fini via FreeResource. Build green (-Dwerror). Committed as 64fd56e231 on wip/xaverius.)

- 2026-11-06T11:23:32Z Defiant: progress 35% (Fixed xaverius_identity_equal false-dedupe for non-PCI/no-UUID devices (commit 00137b60c0). Build green. Next: screen.c private-key mismatch (dixSetPrivate uses XaveriusScreenPrivateKey vs close hook &XaveriusScreenPrivateKeyRec), then missing dispatch handlers.)

- 2026-11-06T11:31:54Z Defiant: progress 50% (Proto.h constants renamed XAV_* → XAVERIUS_* schema (commit c21632db21). Build green. Next: Gpu* model + GpuRegistryRegisterDdxDevice() per Stage 1-4 spec.)

- 2026-11-06T11:44:51Z Defiant: progress 60% (Naming alignment done (commit 53a2089ac7): wire-protocol structs xav* -> Xaverius*, defines XAVERIUS_*, atoms xav_atom_* -> xaverius_atom_*, MakeAtom -> dixAddAtom. Build green (-Dwerror). wip/xaverius: C5/C7 registry fix, identity_equal fix, xaverius.h slimmed, proto.h naming aligned, dixAddAtom migration.)

- 2026-11-06T11:46:06Z Defiant: progress 65% (Dropped XaveriusScreenPrivateKey macro (commit 34546c23ff): screen.c and XaveriusGetScreen now use &XaveriusScreenPrivateKeyRec directly. XaveriusEventBase and XaveriusScreenPrivateKeyRec unchanged. Build green (-Dwerror).)

- 2026-11-06T11:47:03Z Defiant: progress 70% (XaveriusGetScreen is now a real _X_EXPORT'ed function in screen.c (commit 2c38ae36ea). XaveriusScreenFini dropped (close hook handles cleanup). XaveriusEventBase and XaveriusScreenPrivateKeyRec unchanged. Build green (-Dwerror).)

- 2026-11-06T12:19:56Z Defiant: progress 75% (Registry header cleanup done (commit 057b778c50): xaverius_registry.h removed, declarations split between xaverius_intern.h (internal) and xaverius_priv.h (DDX). XaveriusRegisterDeviceDirect → XaveriusRegisterDevice, identity passed by value. Build green (-Dwerror).)

- 2026-11-06T12:22:54Z Defiant: progress 80% (Removed duplicate XaveriusRegisterDevice prototype from xaverius_intern.h (commit 49c1477223). Declaration stays in xaverius_priv.h (DDX-visible). Build green (-Dwerror).)

- 2026-11-06T12:24:54Z Defiant: progress 85% (Renamed registry globals xaverius_devices → xaverius_physical_devices and xaverius_device_count → xaverius_physical_device_count (commit a40bd41b11). Build green (-Dwerror).)

- 2026-11-06T12:26:17Z Defiant: progress 90% (Renamed XaveriusProviderCapabilities → XaveriusDeviceCapabilities (commit 67f60e317f). Build green (-Dwerror).)

- 2026-11-06T12:27:21Z Defiant: progress 95% (Renamed device field callbacks → capabilities to match XaveriusDeviceCapabilities type (commit a85e02a440). Build green (-Dwerror).)

- 2026-11-06T13:23:53Z Defiant: progress 15% (Stage 1 complete (commit 71876de44c, amended to 197f1f4311 for Xaverius* namespace per W0-20261106-012/W0-20261106-014): Gpu* model introduced — GpuDeviceBackendOps + 4 typed ops tables, ABI version, GpuPhysicalDevice/GpuDeviceBackendBinding/GpuModuleRole internal structs, normative GpuRegistryRegisterDdxDevice/GpuPhysicalDeviceRelease/GpuRegistryRemoveDeviceBackendBinding API, XaPhysicalDevicePublish stub, DIX destructor via CreateNewResourceType. Old XaveriusDevice/XaveriusDeviceCapabilities/XaveriusRegisterDevice removed. Three-header rule kept. Build green (-Dwerror). Next: Stage 2 ModuleRole substrate.)

- 2026-11-06T13:37:46Z Defiant: progress 25% (Stage 2 complete (commit 1253b413c3): XaveriusModuleRole substrate — Create/Retain/Release/Quiesce/Finalize, ADMISSION_OPEN/CLOSED, QUIESCE_PENDING/SUCCESS/FAILURE, lease ownership skeleton, header validation before reading fields. Build green (-Dwerror). wip/xaverius: Stage 1 (commit 197f1f4311, Xaverius* namespace) + Stage 2 done. Next: Stage 3 (registry core + canonical identity + generations).)
