Title: "Xaverius: DDX Operation Tables (4 Tables)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-11-04T19:46:04Z"
Assigned-To: "Defiant"
Doc-Ref: "—"
Slug: task-xaverius-ddx-operation-tables-4-tables

Implementiere komplette DDX backend operation tables gemäß spec/provider-operation-matrix.md: GpuProviderBufferMemoryOps, GpuProviderShaderPipelineOps, GpuProviderDescriptorOps, GpuProviderCommandOps. Alle 6 async ops (WriteBuffer, ReadBuffer, host SignalSemaphore, QueueSubmit, AcquireNextImage, QueuePresent) mit token prepare/commit/reject/complete/retire. Buffer free_buffer, DescriptorSet alloc/free, CommandBuffer pool ownership. Surface capability query completeness. Repository: X11Libre/xserver:wip/xaverius
