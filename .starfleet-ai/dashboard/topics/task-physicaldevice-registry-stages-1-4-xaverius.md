Title: "PhysicalDevice Registry Stages 1-4 (Xaverius)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-11-06T11:15:22Z"
Assigned-To: "Defiant"
Doc-Ref: "—"
Slug: task-physicaldevice-registry-stages-1-4-xaverius

Implement PhysicalDevice registry Stages 1-4 per active task active-physical-device-registry-task-2026-11-05.md + W0-20261105-003 handoff, with W0-20261106-002/-003/-004/-005 as corrective addenda. Three agreed headers: xaverius_proto.h (wire only), xaverius_priv.h (DDX-facing API/types), xaverius_intern.h (internal declarations). Gpu* model: GpuPhysicalDevice, GpuDeviceBackendBinding, GpuDeviceBackendOps, GpuDeviceBackendRegistration, GpuModuleRole. Direct DDX PhysicalDevice registration via GpuRegistryRegisterDdxDevice(). No Provider API, no per-Screen device registration, no protocol handler implementation before Stage 1-4 acceptance. Branch: X11Libre/xserver:wip/xaverius
