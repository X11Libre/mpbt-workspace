# Skill: xaverius-implementation

Implementation of the XAverius extension (Vulkan-like compute/presentation API over X11) for XLibre X server. This skill covers request parsing, response assembly, and event delivery using xlibre's new macros (`X_REQUEST_HEAD_STRUCT`, `X_SEND_REPLY_SIMPLE`, `X_SEND_REPLY_WITH_RPCBUF`, `x_rpcbuf_t`) — **no SProcs**.

## Current State (as of wip/xaverius)

| File | Status |
|------|--------|
| `Xext/xaverius/xaverius_proto.h` | **Complete wire protocol** (all 48 requests, 9 events, replies, XGE events, static asserts) — wire protocol ONLY |
| `Xext/xaverius/xaverius_priv.h` | **Per-screen private API for DDX drivers** — `XaveriusDDXOps` callbacks struct, `XaveriusScreenInit()` — DDX-facing API ONLY |
| `Xext/xaverius/xaverius_intern.h` | **Internal definitions** — `ProcXAveriusDispatch`, `XaveriusScreenRec`, `XaveriusScreenPrivateKeyRec` — internal to extension |
| `Xext/xaverius/xaverius_screen.c` | Per-screen state allocation/deallocation via `devPrivates` + screen close hook |
| `Xext/xaverius/init.c` | Extension init/fini, registers dispatch (proc & sproc = same handler) + per-screen private key |
| `Xext/xaverius/dispatch.c` | Dispatch switch on `subopcode`, `QueryVersion` implemented |
| `Xext/xaverius/meson.build` | Static library |

**Implemented:** `XAV_REQ_QUERY_VERSION` (subopcode 0)
**Stubbed:** None yet — subopcodes 1–47 return `BadRequest` from dispatch default case
**To implement:** Device ops, Buffer/Memory, Queue/Submit, Presentation handlers via per-screen `XaveriusDDXOps` callbacks

## Spec Location

`_WORK_/xav/xav-design/spec/` — full spec (wire-protocol.md, devices.md, queue-submission.md, synchronization.md, memory-buffers.md, shaders-pipelines.md, presentation.md, resource-lifetime.md, errors.md, command-recording.md, conformance.md, request-audit.md, events.md)

**Wichtig — laufende Spec-Sync:**

1. **Spec-Repo regelmäßig pullen** — es können Updates kommen (Design-Iterationen). Vor jedem neuen Implementierungsblock: `cd _WORK_/xav/xav-design && git pull`
2. **`IMPLEMENTATION_COORDINATION.md` beachten** — wird vom Design-Agent geschrieben, enthält Koordinations-Infos, Entscheidungen, offene Fragen. Kann **auch für Kommunikation mit dem Design-Agent genutzt werden**: Änderung schreiben, committen, Branch auf origin pushen → Design-Agent sieht es beim nächsten Pull.

## xlibre Macros to Use

### Request Parsing (from `dix/request_priv.h`)

```c
// Declare + check exact size
X_REQUEST_HEAD_STRUCT(xavCreateBufferReq);

// Declare + check at least size (for variable-length requests)
X_REQUEST_HEAD_AT_LEAST(xavCreateDeviceReq);

// Swap individual fields if client->swapped
X_REQUEST_FIELD_CARD32(device_xid);
X_REQUEST_FIELD_CARD64(size);
X_REQUEST_FIELD_CARD32(usage_flags);

// Variable-length fields after fixed struct
X_REQUEST_VAR_BEGIN();
X_REQUEST_VAR_FIELD(ptr, len);
X_REQUEST_VAR_FIELD_CARD32(array_ptr, count);
X_REQUEST_VAR_END();  // requires fully consumed

// Fixed trailing arrays (count implied by request length)
X_REQUEST_VAR_ARRAY(ptr, count_out, elemsize);

// Trailing raw bytes (no embedded length)
X_REQUEST_VAR_REST(ptr, len);
```

### Response Assembly

```c
// Simple reply (fixed size, no payload)
X_SEND_REPLY_SIMPLE(client, reply_struct);

// Reply with rpcbuf payload (variable-length data)
x_rpcbuf_t rpcbuf = { 0 };
x_rpcbuf_write_CARD32(&rpcbuf, value);
x_rpcbuf_write_binary_pad(&rpcbuf, data, len);
X_SEND_REPLY_WITH_RPCBUF(client, reply_struct, rpcbuf);
```

### rpcbuf Operations (`dix/rpcbuf_priv.h`)

```c
x_rpcbuf_t rpcbuf = { 0 };  // zero-init
x_rpcbuf_write_CARD8(&rpcbuf, val);
x_rpcbuf_write_CARD16(&rpcbuf, val);  // auto-swaps if rpcbuf.swapped
x_rpcbuf_write_CARD32(&rpcbuf, val);
x_rpcbuf_write_CARD64(&rpcbuf, val);
x_rpcbuf_write_binary_pad(&rpcbuf, data, len);
x_rpcbuf_write_string_pad(&rpcbuf, str);
x_rpcbuf_write_string_0t_pad(&rpcbuf, str);
x_rpcbuf_write_counted_string_pad(&rpcbuf, str);
x_rpcbuf_write_rect(&rpcbuf, x, y, w, h);
x_rpcbuf_pad(&rpcbuf);  // pad to 4-byte boundary
CARD32 units = x_rpcbuf_wsize_units(&rpcbuf);  // for reply.length
x_rpcbuf_clear(&rpcbuf);  // free after send
```

### Event Delivery (XGE)

```c
xavAsyncErrorEvent ev = { 0 };
ev.header.response_type = X_GenericEvent;
ev.header.extension = XaveriusEventBase;  // extEntry->eventBase
ev.header.evtype = XAV_EVENT_ASYNC_ERROR;
ev.device_xid = device_xid;
ev.error_code = error_code;
ev.origin = origin;
ev.submission_token = token;
ev.resource_xid = resource_xid;
x_rpcbuf_t rpcbuf = { 0 };
X_SEND_REPLY_WITH_RPCBUF(client, ev, rpcbuf);  // reuses reply machinery for XGE
```

**Note:** `XGE` events use the same `X_SEND_REPLY_WITH_RPCBUF` machinery. The header has `response_type = X_GenericEvent` and `extension = XaveriusEventBase`.

## Implementation Rules

### 1. One Request Handler Per Subopcode

Each subopcode gets its own `static int ProcXaverius<Name>(ClientPtr client)` in `dispatch.c` (or split files per logical group). The main dispatch switches on `stuff->subopcode`.

### 2. Request Validation

- **Always** use `X_REQUEST_HEAD_STRUCT` (fixed size) or `X_REQUEST_HEAD_AT_LEAST` (variable)
- Validate all resource IDs via `dixLookupResource()` or `SecurityCheckResource()`
- Check bounds: queue family indices, memory type indices, buffer offsets, etc.
- Return standard X11 errors: `BadValue`, `BadLength`, `BadAlloc`, `BadMatch`, `BadAccess`
- Map XAverius-specific errors to X11 errors + send XGE `AsyncError` event with `XAV_ERROR_*` code

### 3. Resource Management

- Each XID (device, buffer, memory, semaphore, fence, command pool, command buffer, pipeline, descriptor set/layout/pool, swapchain, surface, shader module) is a **DIX resource** with its own `RESTYPE`
- Register resource types in `Xext/xaverius/resource_types.h` (create this file)
- Use `CreateNewResource()`, `LookupResource()`, `FreeResource()`, `ChangeResourceValue()`
- Device lifetime: track generation counter for `DEVICE_LOST` events

### 4. Reply Assembly

- **Fixed-size replies**: populate struct, `X_SEND_REPLY_SIMPLE`
- **Variable replies**: populate fixed header, use `x_rpcbuf_t` for variable payload, `X_SEND_REPLY_WITH_RPCBUF`
- **Always** set `reply.length` correctly (handled by macro via `x_rpcbuf_wsize_units`)
- Byte-swapping is automatic via macros when `client->swapped`

### 5. Event Generation

- **XGE events only** (no legacy events). Base = `XaveriusEventBase` from `extEntry->eventBase`
- Event types: `XAV_EVENT_ASYNC_ERROR` (0), `DEVICE_LOST` (1), `DEVICE_STATUS_CHANGED` (2), `DEVICE_MEMORY_PRESSURE` (3), `DEVICE_IDLE` (4), `SUBMISSION_COMPLETE` (5), `SUBMISSION_FAILED` (6), `IMAGE_RELEASED` (7), `PRESENTATION_COMPLETE` (8)
- Use `x_rpcbuf_t` for variable event payload (e.g., `submission_token`, `presentation_token`)
- Deliver via `X_SEND_REPLY_WITH_RPCBUF` (client must have selected the event mask via `SelectEvents`)

### 6. Byte Order

- All macros in `request_priv.h` handle swapping when `client->swapped`
- `x_rpcbuf_t.swapped` field controls payload swapping
- **Never** manually call `swapl`/`swaps`/`swapll` — use the macros

### 7. Error Handling

```c
// Validation failure
return BadValue;

// Resource not found
return BadAlloc;  // or BadMatch per spec

// Internal allocation failure
rpcbuf.error = TRUE;  // X_SEND_REPLY_WITH_RPCBUF checks this
```

### 8. Iterative Workflow

1. **Pick one logical group** (e.g., Device Enumeration: subopcodes 1–3)
2. **Add resource type** in new `resource_types.h`
3. **Implement handlers** in `dispatch.c` (or new `dispatch_<group>.c`)
4. **Add to dispatch switch**
5. **Build test** (`meson compile -C build Xext/xaverius`)
6. **Run conformance** (spec has tests in `_WORK_/xav/xav-design/tests/`)
7. **Commit** — keep history linear, one logical group per commit
8. **Repeat** for next group

**Do not** rewrite existing structure. The `wip/xaverius` branch has the foundation — extend it.

## Implementation Order (Suggested)

| Phase | Subopcodes | Spec Section |
|-------|------------|--------------|
| 1 | 1–3 (Enumerate, GetProperty, GetQueueFamily) | devices.md |
| 2 | 4–6 (CreateDevice, CreateDefaultDevice, DestroyDevice) | devices.md, resource-lifetime.md |
| 3 | 7 (GetMemoryProperties) | memory-buffers.md |
| 4 | 8–14 (Buffer & Memory ops) | memory-buffers.md |
| 5 | 15–21 (Descriptor Sets) | shaders-pipelines.md |
| 6 | 22–23 (Pipeline Layout, Compute Pipeline) | shaders-pipelines.md |
| 7 | 24–27 (Command Pool/Buffer) | command-recording.md |
| 8 | 28 (Queue Submit) | queue-submission.md |
| 9 | 29–33 (Semaphores) | synchronization.md |
| 10 | 34–38 (Fences) | synchronization.md |
| 11 | 39 (DestroyResource), 40 (SelectEvents) | resource-lifetime.md, events.md |
| 12 | 41–47 (Presentation) | presentation.md |

## Spec Sync Rules

1. **Spec-Repo regelmäßig pullen**: `cd _WORK_/xav/xav-design && git pull` — das Spec-Repo kann jederzeit durch den Design-Agent aktualisiert werden; vor jeder Implementierungssession den aktuellen Stand holen.
2. **IMPLEMENTATION_COORDINATION.md beachten**: Geschrieben vom Design-Agent für die Kommunikation mit diesem. Änderungen dort schreiben, committen und den Branch auf `origin` pushen.

## Learning Capture

When you find issues (missing macros, wrong patterns, spec mismatches), **update this skill** with:
- The problematic pattern
- The correct pattern
- Any new macro needed

Example entry in "Lessons Learned" section:
```markdown
### 2026-11-03: QueueSubmit variable arrays
**Problem:** `xavQueueSubmitReq` has 4 variable arrays (command buffers, wait semaphores, signal semaphores, commands) with counts in header.
**Solution:** Use `X_REQUEST_VAR_FIELD_CARD32` for each array after swapping count fields. `X_REQUEST_VAR_END()` ensures no trailing bytes.
**Macro used:** `X_REQUEST_VAR_FIELD_CARD32(ptr, count)`
```

## Build Integration

The existing `meson.build` works. When adding new `.c` files, add to `srcs_xaverius` array.

```meson
srcs_xaverius = [
    'init.c',
    'dispatch.c',
    'dispatch_devices.c',   # new
    'dispatch_memory.c',    # new
    ...
]
```

## Testing

- Unit tests: `_WORK_/xav/xav-design/tests/` (pytest-based, run against live server)
- Conformance: `IMPLEMENTATION_COORDINATION.md` lists test matrix
- Manual: `simple-xinit` with test client (see `xserver-testing` skill)

## Related Skills

- `coding-style-xserver` — XLibre coding style
- `wire-format` — reply wire format (rpcbuf padding done by OS layer)
- `xserver-testing` — simple-xinit for testing

## Extension Header Layout

Die Extension verwendet drei getrennte Header mit klar getrennten Verantwortlichkeiten:

| Header | Zweck | Inhalt | Verwendet von |
|--------|-------|--------|---------------|
| `xaverius_proto.h` | **Reines Wire-Protocol** (keine anderen Definitionen!) | CARD8/CARD16/CARD32/CARD64 Structs für Requests/Replies/XGE-Events, Subopcode-Defines, Error-Codes, Event-IDs, `sz_*` Konstanten, Static Asserts für Wire-Größen | Alle Extension-Dateien + Client-Bindings |
| `xaverius_priv.h` | **Definitions für außerhalb der Extension** (z. B. DDX) | Per-Screen DDX API (`XaveriusDDXOps`, `XaveriusScreenInit/Fini`), Screen-Private-Struct, DevPrivateKey für Client-State | DDX-Treiber, Extension-Init, externe Module |
| `xaverius_intern.h` | **Definitions für mehrere Source-Dateien innerhalb der Extension** | Interne Structs (Device, Buffer, Memory, Semaphore, Fence, Command-Pool, Command-Buffer, Pipeline, Descriptor-Set, Swapchain, Surface), RESTYPE-Registrierung, interne Hilfsfunktionen, Resource-Lookup | Alle Extension-interne Source-Dateien (`dispatch_*.c`, `events.c`, `resources.c`, `init.c`) |

**Regel:** Nie Definitionen in `xaverius_proto.h` ablegen, die nicht zum reinen Wire-Protocol gehören. Nie interne Structs in `xaverius_priv.h` ablegen, die nur innerhalb der Extension gebraucht werden.

## Files to Create/Modify

```
Xext/xaverius/
├── resource_types.h        # NEW: RESTYPE definitions (in xaverius_intern.h)
├── xaverius_proto.h        # EXISTING: reines Wire-Protocol, nicht modifizieren
├── xaverius_priv.h         # EXISTING: per-screen DDX API (XaveriusDDXOps, XaveriusScreenInit/Fini)
├── xaverius_intern.h       # NEW: interne Definitions für mehrere Extension-Source-Dateien
├── xaverius_screen.c       # EXISTING: per-screen state allocation
├── xaverius_stubs.c        # ENTFERNT: ersetzt durch xaverius_device.c mit echten Handlern
├── dispatch.c              # EXTEND: add handlers
├── dispatch_devices.c      # NEW: device enumeration/creation
├── dispatch_memory.c       # NEW: memory/buffer ops
├── dispatch_sync.c         # NEW: semaphores/fences
├── dispatch_commands.c     # NEW: command pools/buffers/submit
├── dispatch_pipelines.c    # NEW: descriptor sets, pipelines
├── dispatch_presentation.c # NEW: surfaces, swapchains, present
├── events.c                # NEW: event generation helpers
└── resources.c             # NEW: resource lookup/cleanup helpers
```

## Macros Reference Quick-Start

```c
// Handler skeleton
static int ProcXAveriusCreateBuffer(ClientPtr client)
{
    X_REQUEST_HEAD_STRUCT(xavCreateBufferReq);

    // Swap fields if needed
    X_REQUEST_FIELD_CARD32(device_xid);
    X_REQUEST_FIELD_CARD32(buffer_xid);
    X_REQUEST_FIELD_CARD64(size);
    X_REQUEST_FIELD_CARD32(usage_flags);

    // Validate
    DevicePtr dev = dixLookupResource(stuff->device_xid, XAVERIUS_DEVICE_RESTYPE);
    if (!dev) return BadAlloc;

    // ... create buffer resource ...

    // Reply — only set used fields, macros fill header themselves
    xavCreateBufferReply rep = {
        .status = XAV_STATUS_SUCCESS,
    };
    X_SEND_REPLY_SIMPLE(client, rep);
    return Success;
}

// Variable-length reply with rpcbuf
static int ProcXAveriusEnumeratePhysicalDevices(ClientPtr client)
{
    X_REQUEST_HEAD_STRUCT(xavEnumeratePhysicalDevicesReq);

    x_rpcbuf_t rpcbuf = { .swapped = client->swapped };
    x_rpcbuf_write_CARD32(&rpcbuf, device_count);
    for (each device) {
        x_rpcbuf_write_CARD32(&rpcbuf, info.physical_device_xid);
        x_rpcbuf_write_CARD32(&rpcbuf, info.device_type);
        // ...
        x_rpcbuf_write_counted_string_pad(&rpcbuf, info.device_name);
    }

    xavEnumeratePhysicalDevicesReply rep = {
        .status = XAV_STATUS_SUCCESS,
    };
    X_SEND_REPLY_WITH_RPCBUF(client, rep, rpcbuf);
    x_rpcbuf_clear(&rpcbuf);
    return Success;
}
```

## Patterns from Namespace Extension (Xext/namespace)

The `Xext/namespace` extension is the reference implementation for modern xlibre extensions. Key patterns to follow:

### 1. Split Handler Files (not one giant dispatch.c)

```
Xext/namespace/
├── namespace.h           # shared structs, inline privates, public API
├── namespaceproto.h      # wire protocol (requests, replies, XGE events, sizes)
├── proto.c               # ALL request handlers (one per minor opcode)
├── config.c              # model setters (shared with config loader)
├── init.c                # extension registration, resource type init
├── hooks.h               # hook declarations
├── hook-ext-access.c     # QueryExtension access control
├── hook-ext-dispatch.c   # per-minor-opcode dispatch access control
└── meson.build
```

**For Xaverius:** Split `dispatch.c` into logical groups:
- `dispatch_devices.c` — device enumeration/creation (subopcodes 1-6)
- `dispatch_memory.c` — memory/buffer ops (subopcodes 7-14)
- `dispatch_sync.c` — semaphores/fences (subopcodes 29-38)
- `dispatch_commands.c` — command pools/buffers/submit (subopcodes 24-28)
- `dispatch_pipelines.c` — descriptor sets, pipelines (subopcodes 15-23)
- `dispatch_presentation.c` — surfaces, swapchains, present (subopcodes 41-47)
- `events.c` — XGE event generation helpers
- `resources.c` — resource lookup/cleanup helpers

### 2. Shared Model Layer (config.c pattern)

Namespace puts all **namespace model mutations** in `config.c`:
- `XnsCreate()`, `XnsDelete()`, `XnsSetCaps()`, `XnsAddToken()`, `XnsRemoveToken()`
- Shared between **protocol handlers** and **config loader** (`XnsLoadConfig()`)
- Single source of truth for validation, error codes, lifecycle

**For Xaverius:** Create `xaverius_model.c` with:
- `XavCreateDevice()`, `XavDestroyDevice()`, `XavCreateBuffer()`, `XavAllocateMemory()`, etc.
- Device generation counter for `DEVICE_LOST`
- Resource type registration
- Called by both protocol handlers and any future config loader

### 3. Xace Hooks for Access Control — NOT NEEDED FOR XAVERIUS

Namespace uses two Xace hooks for per-namespace isolation (security boundary between namespaces). **Xaverius does not need this** — it has no per-client security domains. All Xaverius requests are allowed for any connected client (standard X11 access model). The device capabilities (queue families, features) are advertised via `GetPhysicalDeviceQueueFamilyProperties` and `GetPhysicalDeviceProperty`, not enforced via Xace hooks.

**Do not add** `hook-ext-access.c` or `hook-ext-dispatch.c` for Xaverius.

### 4. Per-Client Private Data (DevPrivateKey)

```c
// namespace.h
extern DevPrivateKeyRec namespaceClientPrivKeyRec;

static inline struct XnamespaceClientPriv *XnsClientPriv(ClientPtr client) {
    if (client == NULL) return NULL;
    return dixLookupPrivate(&client->devPrivates, &namespaceClientPrivKeyRec);
}

// init.c (or resources.c)
DevPrivateKeyRec namespaceClientPrivKeyRec = { .type = PRIVATE_TYPE_INT };
```

**For Xaverius:** Add in `xaverius.h`:
```c
extern DevPrivateKeyRec xaveriusClientPrivKeyRec;

struct XaveriusClientPriv {
    struct XaveriusDevice *current_device;  // for implicit device context
    Bool isSuperClient;                     // equivalent to ns->superPower
};

static inline struct XaveriusClientPriv *XavClientPriv(ClientPtr client) {
    return dixLookupPrivate(&client->devPrivates, &xaveriusClientPrivKeyRec);
}
```

### 5. Variable-Length Request Parsing (exact pattern from proto.c)

```c
// Three variable fields in declared order (AddAuthToken: name, proto, data)
X_REQUEST_HEAD_AT_LEAST(xXnsAddAuthTokenReq);
X_REQUEST_FIELD_CARD16(nameLen);
X_REQUEST_FIELD_CARD16(protoLen);
X_REQUEST_FIELD_CARD16(dataLen);

const char *name, *proto, *data;
X_REQUEST_VAR_BEGIN();
X_REQUEST_VAR_FIELD(name,  stuff->nameLen);
X_REQUEST_VAR_FIELD(proto, stuff->protoLen);
X_REQUEST_VAR_FIELD(data,  stuff->dataLen);
X_REQUEST_VAR_END();
```

**For Xaverius:** `CreateDevice` has queue families (CARD32 array), features (CARD32 array), extensions (CARD16 len + string). Use:
- `X_REQUEST_VAR_FIELD_CARD32(ptr, count)` for fixed-size arrays
- `X_REQUEST_VAR_FIELD(ptr, len)` for strings
- `X_REQUEST_VAR_END()` to enforce no trailing bytes

### 6. Variable-Length Replies with rpcbuf (exact pattern)

```c
// ListNamespaces: iterate, write records, send
x_rpcbuf_t buf = { .swapped = client->swapped, .err_clear = TRUE };
CARD32 count = 0;
xorg_list_for_each_entry(ns, &ns_list, entry) {
    x_rpcbuf_write_CARD32(&buf, XnsCaps(ns));
    x_rpcbuf_write_CARD32(&buf, XnsAttrs(ns));
    x_rpcbuf_write_CARD32(&buf, (CARD32) ns->refcnt);
    x_rpcbuf_write_CARD32(&buf, XnsCountTokens(ns));
    x_rpcbuf_write_CARD16(&buf, (CARD16) strlen(ns->name));
    x_rpcbuf_write_CARD16(&buf, 0 /* pad */);
    x_rpcbuf_write_string_pad(&buf, ns->name);
    count++;
}
xXnsListNamespacesReply reply = { .count = count };
X_REPLY_FIELD_CARD32(count);
return X_SEND_REPLY_WITH_RPCBUF(client, reply, buf);
```

**Key details:**
- Initialize `buf = { .swapped = client->swapped, .err_clear = TRUE }`
- Write count first in rpcbuf, then records
- Set reply header `count` field, swap via `X_REPLY_FIELD_CARD32(count)`
- Use `x_rpcbuf_write_string_pad()` for counted strings (CARD16 len + bytes + pad)
- `x_rpcbuf_write_CARD16(&buf, 0)` for explicit padding after length

### 7. XGE Event Delivery (same machinery)

```c
// ListAuthTokens reply includes records with handles + protocol names (NO key data)
x_rpcbuf_t buf = { .swapped = client->swapped, .err_clear = TRUE };
xorg_list_for_each_entry(at, &ns->auth_tokens, entry) {
    x_rpcbuf_write_CARD32(&buf, at->handle);
    x_rpcbuf_write_CARD16(&buf, (CARD16)(at->authProto ? strlen(at->authProto) : 0));
    x_rpcbuf_write_CARD16(&buf, 0);
    x_rpcbuf_write_string_pad(&buf, at->authProto);
    /* deliberately NOT writing authTokenData - no key exfiltration */
    count++;
}
```

**For Xaverius:** Use same pattern for `EnumeratePhysicalDevices`, `GetQueueFamilyProperties`, `GetPhysicalDeviceMemoryProperties`, etc.

### 8. Both proc and sproc point to same handler

```c
// namespace proto.c
ExtensionEntry *ext = AddExtension(XNS_EXTENSION_NAME, 0, 0,
                                   ProcXnsDispatch, ProcXnsDispatch,  // BOTH proc & sproc
                                   NULL, StandardMinorOpcode);
```

**For Xaverius:** Same — `ProcXaveriusDispatch` handles both swapped and unswapped because macros do the swapping.

### 9. Resource Type Registration Pattern

In `init.c` or `resources.c`:
```c
// Register custom RESTYPEs at init time
int XavDeviceRestype = CreateNewResourceType(XavFreeDevice);
int XavBufferRestype = CreateNewResourceType(XavFreeBuffer);
int XavMemoryRestype = CreateNewResourceType(XavFreeMemory);
// ...
```

Free functions handle cleanup (unbind memory, destroy Vulkan objects, etc.)

### 10. Generation Counters for LOST Events

```c
// In XnsDeleteNamespace: increment generation so stale clients see DEVICE_LOST
ns->generation++;  // or similar
```

**For Xaverius:** Each `XaveriusDevice` has `generation` counter. On `DestroyDevice` or `DeviceLost`, increment. Include in `AsyncError` and `DeviceLost` events.

## Lessons Learned from Namespace

| Pattern | Xaverius Application |
|---------|---------------------|
| Split handlers by logical group | `dispatch_devices.c`, `dispatch_memory.c`, etc. |
| Shared model layer | `xaverius_model.c` with `XavCreateDevice()` etc. |
| DevPrivateKey for client state | `XavClientPriv()` for current device, super-client flag |
| Xace hooks for access control | If needed: `hook-ext-access/dispatch` |
| `xorg_list` for all collections | `ns_list`, `auth_tokens` → `xav_device_list`, `xav_buffer_list` |
| Generation counters | `device->generation` for `DEVICE_LOST` |
| `err_clear = TRUE` on rpcbuf | Auto-clear on allocation failure |
| String writing: `x_rpcbuf_write_string_pad` | For device names, extension names, shader entry points |
| Never write secrets to wire | Namespace doesn't write `authTokenData`; Xaverius: don't write shader SPIRV to error events |

## Notes

- **No SProcs** — xlibre macros handle swapped clients automatically
- **Spec is normative** — wire-protocol.md defines exact struct layout; `xaverius_proto.h` has static asserts
- **Resource types** must be registered before use (in `init.c` or `resources.c`)
- **Generation counters** for device/surface/swapchain to handle `DEVICE_LOST` / `SURFACE_LOST` correctly
- **Thread safety**: X server is single-threaded; no locking needed for extension state

## Spec-Sync Rules

1. **Spec-Repo regelmäßig pullen:** `cd _WORK_/xav/xav-design && git pull` — es können Updates kommen, die für die Implementierung relevant sind. Vor jedem Commit die Spec prüfen.
2. **IMPLEMENTATION_COORDINATION.md beachten:** Geschrieben vom Design-Agent, für Kommunikation mit diesem nutzen: Änderung schreiben, committen, Branch auf origin pushen.
3. Spec-Änderungen immer im Design-Repo (`_WORK_/xav/xav-design`) diskutieren und committen, nicht im Xserver-Repo.

## Header File Convention (Mandatory)

Per Enterprise directive: strict three-way split, no overlap.

| Header | Contains | Does NOT contain |
|--------|----------|------------------|
| `xaverius_proto.h` | Wire protocol ONLY (request/reply/event structs, constants, static asserts) | No internal structs, no DDX API, no handler prototypes |
| `xaverius_priv.h` | DDX-facing API ONLY (`XaveriusDDXOps`, `XaveriusScreenInit`) | No wire protocol, no internal structs |
| `xaverius_intern.h` | Internal definitions shared by source files (`ProcXAveriusDispatch`, `XaveriusScreenRec`, `XaveriusScreenPrivateKeyRec`, helper declarations) | No wire protocol, no DDX API |

**Rules:**
- Never put non-wire-protocol in `xaverius_proto.h`
- Never put internal structs/helper in `xaverius_priv.h`
- `xaverius.h` **does not exist** — deleted. All definitions live in the three headers above.
- No SProcs — proc and sproc use same handler (`ProcXAveriusDispatch` for both)

## Per-Screen Privates (DDX Integration)

Xaverius allocates a per-screen structure owned by the extension. DDX drivers register their callbacks via `XaveriusDDXOps`:

- **`XaveriusScreenInit(ScreenPtr, const XaveriusDDXOps*)`** — called by DDX during screen init; Xaverius allozates state, DDX fills in `ops`. Screen close cleanup is automatic via `dixScreenHookClose()` hook registered by `XaveriusScreenInit`.
- **`XaveriusDDXOps`** struct contains only callbacks the DDX actually implements (currently `ScreenInit`, `ScreenFini`).
- **`XaveriusScreenRec`** holds `pScreen`, `ops`, `driver_private` (DDX-owned), `initialized`.
- Screen private key (`XaveriusScreenPrivateKeyRec`) registered at extension init time in `init.c`.

See `xaverius_priv.h` for the full API.
