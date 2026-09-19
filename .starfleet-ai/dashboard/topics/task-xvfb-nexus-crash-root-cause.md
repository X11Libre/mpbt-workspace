# Xvfb/Xnest crash with +extension NEXUS: DDX arrays indexed by myNum fail when nexus shifts screen IDs

## Root Cause Analysis

### Problem
Xvfb crashes with segmentation fault when started with `+extension NEXUS`. Xnest likely has the same issue.

### Technical Details

**The nexus architecture:**
- `NexusPreInit()` creates a dummy nexus screen at index 0 via `AddScreen(nexus_dummy_screen_init, ...)` before `InitOutput()`
- Physical DDX screens (Xvfb, Xnest) are created during `InitOutput()` via their own `AddScreen()` calls
- Result: nexus dummy = screen 0, physical screens = 1, 2, 3...

**Xvfb's internal structure:**
```c
// hw/vfb/InitOutput.c
static vfbScreenInfo *vfbScreens;  // array sized to vfbNumScreens
static int vfbNumScreens;          // counts Xvfb screens ONLY

// In vfbScreenInit:
vfbScreenInfoPtr pvfb = &vfbScreens[pScreen->myNum];  // CRASH HERE
```

When nexus is disabled: Xvfb screen 0 → `vfbScreens[0]` ✓
When nexus enabled: Xvfb screen 0 → `vfbScreens[1]` (out of bounds!) → **SEGFAULT**

**Affected DDXes (confirmed/suspected):**
- **Xvfb** - confirmed crash (uses `vfbScreens[pScreen->myNum]`)
- **Xnest** - likely same issue (uses `xnestDefaultWindows[pScreen->myNum]`, `xnestScreenSaverWindows[pScreen->myNum]`)
- **Xephyr** - needs investigation (kdrive-based, may use similar patterns)
- **Xorg** - likely affected in various places

### Current Test Status
| DDX | `-extension NEXUS` | `+extension NEXUS` |
|-----|-------------------|-------------------|
| Xnest | ✅ N screens | ✅ 1 nexus + N screens |
| Xvfb | ✅ 1 screen | ❌ **SEGFAULT** |
| Xephyr | ✅ 1 screen | ✅ 1 nexus + 1 physical |

Xephyr works because kdrive architecture may handle dynamic screen counts differently.

### Possible Solutions

1. **DDX-agnostic: Shift DDX screen indices internally**
   - Add offset to DDX screen arrays based on nexus screen count
   - Complex, invasive per DDX

2. **DDX-agnostic: Virtual screen mapping**
   - Create abstraction layer mapping logical → physical screen indices
   - Centralized in DIX, transparent to DDXes

3. **Per-DDX fixes (incremental)**
   - Xvfb: Change `vfbScreens` to dynamic array or hash map keyed by ScreenPtr
   - Xnest: Same pattern
   - Each DDX fixes its own screen indexing

4. **Nexus screen as overlay, not base screen**
   - Don't create nexus as screen 0
   - Nexus exists as extension only, DDX screens keep 0-based indexing
   - Nexus tracks physical screens via separate registry

5. **Lazy nexus initialization**
   - Don't create nexus screen in `NexusPreInit`
   - Create nexus screen as first physical screen initializes
   - Nexus screen gets highest index (or special handling)

### Recommended Approach

**Option 4 (Nexus as overlay) + Option 5 (Lazy init)** seems cleanest:
- Nexus doesn't claim screen 0
- Physical DDX screens keep 0-based indexing
- Nexus exists as virtual coordinator, registered via extension mechanism
- Physical screens register with nexus via `AddScreen` hook
- NexusExtensionInit validates and sets up coordinator

This avoids breaking DDX assumptions about screen numbering.

### Next Steps
1. Document all DDX screen-array usages (Xvfb, Xnest, Xephyr, Xorg, Xquartz, Xwin)
2. Prototype Option 4/5 approach
2. Test with all DDXes
3. Submit PR

## Related Files
- `Xext/nexus/nexus.c` - nexus core implementation
- `Xext/nexus/nexus.h` - nexus API
- `dix/dispatch.c` - AddScreen hook for physical screen registration
- `hw/vfb/InitOutput.c` - Xvfb screen management (crash source)
- `hw/xnest/Screen.c` - Xnest screen management (likely affected)
- `hw/kdrive/ephyr/*.c` - Xephyr (works, needs verification)
- `hw/xfree86/common/xf86Init.c` - Xorg (needs audit)
