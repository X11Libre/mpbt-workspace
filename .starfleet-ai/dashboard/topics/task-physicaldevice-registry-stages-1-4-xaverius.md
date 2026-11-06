Title: "PhysicalDevice Registry Stages 1-4 (Xaverius)"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Defiant"
Created-By: "Enterprise"
Created: "2026-11-06T11:15:22Z"
Doc-Ref: "—"

Implement PhysicalDevice registry Stages 1-4 per active task active-physical-device-registry-task-2026-11-05.md + W0-20261105-003 handoff, with W0-20261106-002/-003/-004/-005 as corrective addenda. Three agreed headers: xaverius_proto.h (wire only), xaverius_priv.h (DDX-facing API/types), xaverius_intern.h (internal declarations). Gpu* model: GpuPhysicalDevice, GpuDeviceBackendBinding, GpuDeviceBackendOps, GpuDeviceBackendRegistration, GpuModuleRole. Direct DDX PhysicalDevice registration via GpuRegistryRegisterDdxDevice(). No Provider API, no per-Screen device registration, no protocol handler implementation before Stage 1-4 acceptance. Branch: X11Libre/xserver:wip/xaverius

- 2026-11-06T11:19:23Z Defiant: began work

- 2026-11-06T11:22:37Z Defiant: progress 25% (C5/C7 fix: canonical PhysicalDevice DIX resource type via CreateNewResourceType + destructor, RegistryInit returns bool, Fini via FreeResource. Build green (-Dwerror). Committed as 64fd56e231 on wip/xaverius.)

- 2026-11-06T11:23:32Z Defiant: progress 35% (Fixed xaverius_identity_equal false-dedupe for non-PCI/no-UUID devices (commit 00137b60c0). Build green. Next: screen.c private-key mismatch (dixSetPrivate uses XaveriusScreenPrivateKey vs close hook &XaveriusScreenPrivateKeyRec), then missing dispatch handlers.)
