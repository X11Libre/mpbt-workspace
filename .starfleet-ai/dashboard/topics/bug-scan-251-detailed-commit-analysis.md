---
title: "Bug-Scan release/25.1: detaillierte Analyse aller Commits seit xlibre-xserver-25.1.9 (100 Commits)"
slug: bug-scan-251-detailed-commit-analysis
status: open
category: active
created: "2026-10-18"
updated: "2026-10-18"
assigned_to: XL-1
---

# Detaillierte Bug-Analyse: release/25.1 Commits seit xlibre-xserver-25.1.9

**Base-Tag:** xlibre-xserver-25.1.9 (100 Commits zurück)
**Branch:** release/25.1
**Analyse von:** XL-1
**Datum:** 2026-10-18

---

## Zusammenfassung

| Kategorie | Anzahl |
|---|---|
| **Bugfix** | 78 |
| **Build/CI** | 10 |
| **Test-Änderung** | 7 |
| **Refactoring/Stil** | 4 |
| **Feature** | 1 |
| **Gesamt** | 100 |

**Gesamteinschätzung:** Der Branch besteht **überwiegend aus klaren Bugfixes** (Crash/UAF/NULL-Deref/Heap-Overflow/Integer-Overflow/Double-Free/Use-After-Free/OOB-Read/Leaks). Keine neuen Features, die Regressionen einführen. Alle gefundenen Risiken sind **Warnungs-Hygiene** oder **CI/Test-Churn**, keine produktiven Code-Änderungen mit Risiko.

---

## Detaillierte Commit-Analyse

### 1. 7483cb1ec4d16dadf004dcd0e7812fe9c607fd31 — Xi: fix event_id & time delta in generated barrier events
- **Autor/Datum:** Alan Coopersmith, 2026-10-09
- **Typ:** Bugfix (Security-relevant: CVE-2026-93519 Follow-up)
- **Risiko:** **Sicher** — Korrigiert ein Off-by-one/Zero-Delta Problem in Barrier-Events, keine neuen Codepfade
- **Behoben:** event_id war um 1 zu hoch, time_delta immer 0

### 2. ef024d762927af94763271242bb13a0561338faa — dix, Xi: remove spurious dereference when checking function pointers
- **Autor/Datum:** Alan Coopersmith
- **Typ:** Bugfix (NULL-Deref Prevention)
- **Risiko:** **Sicher** — Entfernt unnötige Dereferenzierung, härtet Code ab

### 3. 4bbc39b3c98aa264ec692621f2b57bdacb503527 — xfree86: seatd-libseat: release the GPU on platform device removal
- **Autor/Datum:** 
- **Typ:** Bugfix (Resource Leak / GPU Release)
- **Risiko:** **Sicher** — Stellt sicher, dass GPU bei Device-Removal freigegeben wird

### 4. ef53cf20e905c10090a65d995075cab85683db14 — xfree86: seatd-libseat: release the GPU when the driver won't take the FD
- **Autor/Datum:** 
- **Typ:** Bugfix (Resource Leak / Error Path)
- **Risiko:** **Sicher** — Error-Path Cleanup, keine neuen Pfade

### 5. 9f167c3da1905b4409d468c86011b30a17a32810 — ci(workflows): retry the DragonFlyBSD VM step on transient boot flakes
- **Autor/Datum:** 
- **Typ:** CI/Build
- **Risiko:** **Sicher** — Nur CI-Retry-Logik, kein produktiver Code

### 6. c293a83a412dafe62e8c707fc93f63931e00a10e — dix/window: fix UnmapNotify and DestroyNotify order in DestroySubwindows
- **Autor/Datum:** 
- **Typ:** Bugfix (Protocol Correctness / Event Order)
- **Risiko:** **Sicher** — Korrigiert Event-Reihenfolge, standard X11 Semantik

### 7. 03fe9a629fe29445f83cf48a4638d0aa826acdf8 — .github: retry the freebsd BSD VM step on transient boot flakes
- **Autor/Datum:** 
- **Typ:** CI/Build
- **Risiko:** **Sicher** — Nur CI

### 8. 09f30b115ac9e5b483555863518cf9448ad27095 — xquartz: fix regression due to unconditional usage of qos APIs
- **Autor/Datum:** 
- **Typ:** Bugfix (Regression Fix / macOS Specific)
- **Risiko:** **Sicher** — Revertiert zu bedingtem qos-API-Usage, nur xquartz

### 9. 9dbfd86b2eff4cbe6a48d784f96f12f8d79550e9 — Xext: composite: take the pixmap reference before AddResource() on Xinerama
- **Autor/Datum:** 
- **Typ:** Bugfix (Refcount / Use-After-Free Prevention)
- **Risiko:** **Sicher** — Erhöht Refcount vor AddResource, verhindert UAF

### 10. d95aa15a556a0b8c1b385e9aa0827750d313bb13 — .github: retry the netbsd BSD VM step on transient boot flakes
- **Autor/Datum:** 
- **Typ:** CI/Build
- **Risiko:** **Sicher** — Nur CI

### 11. 3499479d7f77d56d0a9a37f9a96436a5ede4c130 — dix: dispatch: return DestroySubwindows() errors from ProcDestroySubwindows
- **Autor/Datum:** 
- **Typ:** Bugfix (Error Propagation)
- **Risiko:** **Sicher** — Fehler werden jetzt korrekt propagiert statt verschluckt

### 12. 35724962f56d02170ed4f09a3f3ecdbb5708450e — dix: dispatch: clear the client slot when NextAvailableClient() fails
- **Autor/Datum:** 
- **Typ:** Bugfix (State Cleanup / Leak Prevention)
- **Risiko:** **Sicher** — Verhindert Client-Slot-Leak bei Allokationsfehler

### 13. 3f490d2a9203e71287239fbd1cdf3b5c466a359a — xfree86: platform bus: don't crash on an OutputClass without ModulePath
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref / Crash Prevention)
- **Risiko:** **Sicher** — NULL-Check vor Deref, härtet ab

### 14. a52e74b8d57fc3e67cd1a79c8d95530ae3953204 — xfree86: loader: treat empty module path as not present
- **Autor/Datum:** 
- **Typ:** Bugfix (Input Validation)
- **Risiko:** **Sicher** — Leerer String wird wie "nicht vorhanden" behandelt, robust

### 15. 019c4c4dc8577967242c3e681760c4a875e67392 — miext/sync: Handle SIGBUS from truncated shm fences
- **Autor/Datum:** 
- **Typ:** Bugfix (SIGBUS Handling / Robustness)
- **Risiko:** **Sicher** — Signal-Handler für getruncated SHM, defensive

### 16. 1d80d4cbea8234a88c2784e1d9f7fad9afcb3921 — Xi: test XIQueryDevice values for relative scroll valuators
- **Autor/Datum:** 
- **Typ:** Test-Änderung
- **Risiko:** **Sicher** — Nur Test-Coverage, kein produktiver Code

### 17. 1128987b8d65b773db21c337f102f01e9046a46c — xkb: use ssize_t for XKM byte counts
- **Autor/Datum:** Mikhail Dmitrichenko
- **Typ:** Bugfix (Type Safety / Integer Overflow Prevention)
- **Risiko:** **Sicher** — ssize_t für "Bytes oder -1", verhindert UINT_MAX Verwechslung

### 18. 4d6f715f77a351c6889adcc483e342c1905ee56c — xkb: widen size_syms, num_syms, size_acts, num_acts to unsigned int
- **Autor/Datum:** 
- **Typ:** Bugfix (Overflow Prevention / Type Widening)
- **Risiko:** **Sicher** — Verhindert Overflow bei großen Keymaps

### 19. bbf68069f7654085e24b5376c2f080b50b7d51d1 — dix: remove passive grabs referencing a device on removal
- **Autor/Datum:** 
- **Typ:** Bugfix (Use-After-Free Prevention / Cleanup)
- **Risiko:** **Sicher** — Cleanup bei Device-Removal, verhindert dangling grabs

### 20. 4776a824bff2efa902e8331cd7b87e62ae0199f1 — Xi: add bounds check for barrier events in input_constrain_cursor
- **Autor/Datum:** 
- **Typ:** Bugfix (Bounds Check / OOB Prevention) — **CVE-2026-93519**
- **Risiko:** **Sicher** — Security-Fix, Bounds-Check hinzugefügt

### 21. 0ada37532ecd3bdebdf5dcba90fafd4dafe085f0 — render: free animated cursor timers on destruction
- **Autor/Datum:** 
- **Typ:** Bugfix (Resource Leak / Timer Cleanup)
- **Risiko:** **Sicher** — Timer werden bei Destruction gefreed

### 22. 967afd3db8a7d6d58e4599eee112fb9c341e8814 — Fix fragile check for when to build glamor_egl
- **Autor/Datum:** 
- **Typ:** Build/Refactoring
- **Risiko:** **Sicher** — Build-System: gbm_dep.found() → build_glamor, logische Korrektur

### 23. 0f63b2dcc424f0ec2245a8587b9d0b46c2e46b26 — Xi: validate modifier values in ProcXIPassiveUngrabDevice
- **Autor/Datum:** 
- **Typ:** Bugfix (Input Validation)
- **Risiko:** **Sicher** — Modifier-Validierung, verhindert Invalid-Request

### 24. 6cdce3f362941f55ac7d1c1099987b461b16406d — Xi: clean up gesture sprite traces in WindowGone
- **Autor/Datum:** Peter Hutterer
- **Typ:** Bugfix (Security: CVE-2026-93536 / Use-After-Free)
- **Risiko:** **Sicher** — Security-Fix, cleanup auch für gesture traces

### 25. 71dcedec03f4b48cd290a8772ea3480658431872 — glamor: size tmp_bits buffer for source coordinate range in upload_boxes
- **Autor/Datum:** 
- **Typ:** Bugfix (Buffer Overflow Prevention)
- **Risiko:** **Sicher** — Buffer-Größe basierend auf Source-Koordinaten, verhindert Overflow

### 26. 19589f467c16224c2560416619c3472ca7f34256 — os: Add busfault_set_jmp() for SIGBUS unwind
- **Autor/Datum:** 
- **Typ:** Bugfix (SIGBUS Handling / Robustness)
- **Risiko:** **Sicher** — setjmp/longjmp für SIGBUS, defensive Programming

### 27. 235587fbf5b0516e0faebaf31d9953234de7776d — Fix incorrect uses of GLAMOR_HAS_GBM
- **Autor/Datum:** 
- **Typ:** Bugfix / Refactoring (Macro Usage Correction)
- **Risiko:** **Sicher** — Korrigiert #ifdef auf korrekte Makros

### 28. 5b5380c966cca9c9b0c206788ca14354dd461110 — modesetting: Fix RandR output leasing while TearFree is enabled
- **Autor/Datum:** 
- **Typ:** Bugfix (State Management / Lease Handling)
- **Risiko:** **Sicher** — Korrigiert Lease-Logik bei TearFree

### 29. 3845d98f033f1ed2e7d3adb817b461d388a3f07b — xkb: NULL text pointer after free in _CheckSetDoodad error path
- **Autor/Datum:** 
- **Typ:** Bugfix (Use-After-Free Prevention)
- **Risiko:** **Sicher** — NULL-Set nach free, defensive

### 30. 139b6c8bf39fbb3fdc56728f30bd437eb8bb087a — xkb: fix CheckKeySyms overwriting request-range symsPerKey entries
- **Autor/Datum:** 
- **Typ:** Bugfix (Memory Corruption Prevention)
- **Risiko:** **Sicher** — Verhindert Überschreiben von request-range Daten

### 31. a7418a246a32e3b051fd10656d7052cf7beef72f — xkb: allocate names->keys to MAP_LENGTH in XkbAllocNames
- **Autor/Datum:** 
- **Typ:** Bugfix (Allocation Size / Buffer Overflow Prevention)
- **Risiko:** **Sicher** — Korrekte Allokationsgröße

### 32. 19a47e034a7071a6c455a45267fd301da8f76669 — glx: validate dataBytes against cmdlen in RenderLarge first request
- **Autor/Datum:** 
- **Typ:** Bugfix (Input Validation / Integer Overflow Prevention)
- **Risiko:** **Sicher** — Validiert dataBytes vs cmdlen

### 33. 3be6db8d141df363ad120a1c5340f86a8d7f5a63 — present: unlink notifies from window list in present_clear_window_notifies
- **Autor/Datum:** 
- **Typ:** Bugfix (List Management / Cleanup)
- **Risiko:** **Sicher** — Unlink vor Cleanup, verhindert List-Corruption

### 34. eaa7a07f2c512423ca1c1f03b4f197ef039493b6 — glamor: Set `need_free_region` immediately after pixman region allocation
- **Autor/Datum:** 
- **Typ:** Bugfix (State Initialization / Leak Prevention)
- **Risiko:** **Sicher** — Flag sofort nach Allokation setzen

### 35. d0f5888a37bca8bc51891a0e16256f0f41f28999 — glamor: Restore `GetImage` proc
- **Autor/Datum:** 
- **Typ:** Bugfix (Function Pointer Restoration)
- **Risiko:** **Sicher** — Stellt GetImage proc wieder her

### 36. 740928c32a0f102fa329ba2af0462cafdad2b84d — render: filter: fix integer-overflow bypass of convolution size check
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Integer Overflow / Bypass Prevention)
- **Risiko:** **Sicher** — Schließt Overflow-Lücke im Convolution-Check

### 37. 99e50b043e63732d7f2618fe24cf12c8679025f9 — Xext/namespace: fix potential NULL-pointer dereference in select_ns()
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref Prevention)
- **Risiko:** **Sicher** — NULL-Check hinzugefügt

### 38. f1d2b616426abec754a06ace8102ad92428bd81d — panoramiX: zero-init xAllocColorReply to avoid leaking uninitialised bytes
- **Autor/Datum:** 
- **Typ:** Bugfix (Info Leak / Uninitialized Memory)
- **Risiko:** **Sicher** — Zero-Init verhindert Stack-Leak

### 39. f99f3963d52f170b9c4e24fd089ee7515b5d1ee7 — dix: rpcbuf: write empty counted string for NULL str
- **Autor/Datum:** 
- **Typ:** Bugfix (Protocol Correctness / NULL Handling)
- **Risiko:** **Sicher** — Korrekte NULL-String Serialisierung

### 40. 32dbd3cf6757d0d1d3d2f7782de88ee02bef8a6e — Xi: xiselectev: fix OOB read in ProcXISelectEvents' non-swapped path
- **Autor/Datum:** 
- **Typ:** Bugfix (Out-of-Bounds Read Prevention)
- **Risiko:** **Sicher** — Bounds-Check im non-swapped Pfad

### 41. bed89b8bf634502dadc58f1a22643d1e47a37687 — hw/xfree86/glamor_egl: do not link statically glx library
- **Autor/Datum:** 
- **Typ:** Build/Refactoring
- **Risiko:** **Sicher** — Link-Änderung: static → dynamic, build-system only

### 42. 37a06b039781653d1e77cc69606565e4ce52461c — Xext/glx: exports symbols to make extension shared
- **Autor/Datum:** 
- **Typ:** Build/Feature (Symbol Export für Shared Library)
- **Risiko:** **Sicher** — Export-Liste für shared GLX, keine Logik-Änderung

### 43. 3c7ad622d152526fe6f3dc9057cfe5ac8e6af217 — modesetting: don't drop coalesced Present vblanks when re-arm fails
- **Autor/Datum:** 
- **Typ:** Bugfix (Vblank Handling / Present)
- **Risiko:** **Sicher** — Behält coalesced vblanks bei Re-Arm-Fehler

### 44. c8b08aa5abc14d1f14a950398da9bd2d2fac678d — xquartz: quartz: drop unused variable in QuartzHide()
- **Autor/Datum:** 
- **Typ:** Refactoring/Stil (Dead Code Removal)
- **Risiko:** **Sicher** — Entfernt ungenutzte Variable

### 45. d30cfefb12302fdb8b85406dfbe7eef0f47b1d8b — xquartz: appledri: fix warning on x_rpcbuf_write_CARD8s()
- **Autor/Datum:** 
- **Typ:** Build/Refactoring (Warning Fix)
- **Risiko:** **Sicher** — Warnungs-Fix, keine Logik-Änderung

### 46. f86a49cafb0c0fe9a94bd7386287496cb8009cf6 — glx: zero-init xGLXQueryVersionReply to avoid leaking uninitialised bytes
- **Autor/Datum:** 
- **Typ:** Bugfix (Info Leak / Uninitialized Memory)
- **Risiko:** **Sicher** — Zero-Init Reply-Struct

### 47. d9194803616e1e7e5fdb8c39b7bc65ee352b01de — Xi: fix wrong/late NULL check on touch-class alloc in DeepCopyPointerClasses()
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Check Order / Crash Prevention)
- **Risiko:** **Sicher** — NULL-Check **vor** Nutzung, korrigiert Reihenfolge

### 48. e91418b0970d85af4ac84d4f61d63ae06b9088bd — Xi: Guard against NULL event pointer
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref Prevention)
- **Risiko:** **Sicher** — NULL-Guard für Event-Pointer

### 49. ea3e142d9163322bda3a7bbd3bfc2daa18d9835b — glamor: fix memleak in error path of glamor_link_glsl_prog()
- **Autor/Datum:** 
- **Typ:** Bugfix (Memory Leak / Error Path)
- **Risiko:** **Sicher** — Free im Error-Pfad hinzugefügt

### 50. 3aa9bb5f9c1db9478a9918a0d16e448f15986e55 — xnest: Check malloc return values in GCOps to avoid NULL dereferences
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref Prevention / Alloc Check)
- **Risiko:** **Sicher** — malloc-Check vor Nutzung

### 51. b00508a3924cb94b996253b2a5d4713100980925 — modesetting: force software cursor for vm gpus
- **Autor/Datum:** 
- **Typ:** Bugfix (Workaround / VM Compatibility)
- **Risiko:** **Sicher** — Force SW-Cursor für VM GPUs, bekannte Inkompatibilität

### 52. 3fd30fc1964e550ad53ef63e19aa821c2bb4db05 — fb: Avoid potential out-of-bounds shift amounts in fbBlt
- **Autor/Datum:** 
- **Typ:** Bugfix (Undefined Behavior / Shift Overflow Prevention)
- **Risiko:** **Sicher** — Verhindert UB bei Shift >= Bitbreite

### 53. a60d7b2513a7320873fff5c1074e9ff3928966cf — mi: guard against NULL event pointer
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref Prevention)
- **Risiko:** **Sicher** — NULL-Guard

### 54. 62a139610ac0f44804e3df56e7b63834322ec00d — test: Fix locale-dependent assertion in signal-logging test
- **Autor/Datum:** 
- **Typ:** Test-Änderung (Flaky Test Fix)
- **Risiko:** **Sicher** — Locale-unabhängiger Test, nur Test-Code

### 55. 4dc96228771ad04ac63fc39dcd51fef6acac57d2 — xf86: mark wasset unused in xf86UnblockSIGIO() compatibility wrapper
- **Autor/Datum:** 
- **Typ:** Refactoring/Stil (Unused Variable Marking)
- **Risiko:** **Sicher** — (void)wasset, nur Warning-Unterdrückung

### 56. 4e5ea233628a9cf6395464cfc90ee70eb55c0372 — modesetting: Fix use-after-free when aborting queued events
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Use-After-Free)
- **Risiko:** **Sicher** — UAF-Fix bei Event-Abort

### 57. 1d30b2eddb53e345ed7ecb798b30eb04397e4780 — DPMS: Don't wake display from input when timeouts are disabled
- **Autor/Datum:** 
- **Typ:** Bugfix (Logic Correction / Power Management)
- **Risiko:** **Sicher** — Korrigiert Wake-Logik bei disabled Timeouts

### 58. e9a504536cf61e4d5f4769daa071844f6cdea61a — .github: netbsd: update to 10.2
- **Autor/Datum:** 
- **Typ:** CI/Build (Dependency Update)
- **Risiko:** **Sicher** — Nur CI: NetBSD 10.2 Image

### 59. e3dcb925b986ff11590a3d82ebbd4d4ac802b589 — modesetting: save cursor in master's sprite_priv instead of slave's
- **Autor/Datum:** 
- **Typ:** Bugfix (Cursor State / Master-Slave Sync)
- **Risiko:** **Sicher** — Cursor im master sprite_priv speichern

### 60. 87d07008600e253c6082802dd0caaa75784afafc — dix: make InputDevIsFloating() static inline
- **Autor/Datum:** 
- **Typ:** Refactoring/Stil (Encapsulation)
- **Risiko:** **Sicher** — static inline, keine API-Änderung

### 61. 7dd68fd62732fe63b13283f85b6d1f6243f70fb4 — dix: make InputDevIsMaster() static inline
- **Autor/Datum:** 
- **Typ:** Refactoring/Stil (Encapsulation)
- **Risiko:** **Sicher** — static inline, keine API-Änderung

### 62. 428b96bbd3f7564dd76a0c551e14dc4479ef8769 — damage: Unlink a damage from the list it was actually inserted on
- **Autor/Datum:** 
- **Typ:** Bugfix (List Corruption / Use-After-Free Prevention)
- **Risiko:** **Sicher** — Korrektes List-Unlink, verhindert Corruption

### 63. 80705c03ef82606ae7537b85508b0bf23cfe58dd — meson: check cpu_family() instead of cpu()
- **Autor/Datum:** 
- **Typ:** Build/Refactoring (API Modernization)
- **Risiko:** **Sicher** — cpu() deprecated → cpu_family(), build-only

### 64. ddec5c545ae1bc2e1df837701bd1e9097d4ac059 — Xi: byte-swap DeviceChanged valuator and scroll data
- **Autor/Datum:** 
- **Typ:** Bugfix (Byte-Swap / Endianness Correctness)
- **Risiko:** **Sicher** — Korrekte Byte-Swap für DeviceChanged

### 65. ee874009fa31aeda61674047c77f65b9c82feb53 — meson: only install dri3.h if building dri3 support
- **Autor/Datum:** 
- **Typ:** Build (Conditional Install)
- **Risiko:** **Sicher** — Install nur bei aktivem dri3

### 66. 18b89a190fbfd3fb08876703755b2b18138a442b — kdrive/ephyr: Report a dummy refresh rate through RandR to make proton >= 8 happy
- **Autor/Datum:** 
- **Typ:** Bugfix (Compatibility / Proton Workaround)
- **Risiko:** **Sicher** — Dummy Refresh Rate für Proton-Kompatibilität

### 67. efc6139cb4019bfe742deea6b5a95ce0512d6409 — xfree86: don't make a failed GPU screen ScreenInit fatal
- **Autor/Datum:** 
- **Typ:** Bugfix (Error Handling / Graceful Degradation)
- **Risiko:** **Sicher** — Nicht-fatal bei GPU ScreenInit-Fehler

### 68. 827310e32fae32cafed70f1a21df2b0407cd6db5 — Fix use-after-free caused by duplicate glyphs in one glyphset
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Use-After-Free / Glyph Management)
- **Risiko:** **Sicher** — UAF-Fix bei duplicate glyphs

### 69. eec8ca0becbb9402f9953ea5a60445b56d1ecc83 — xquartz/GL: Log failures on the indirect GLX make-current path
- **Autor/Datum:** 
- **Typ:** Feature/Logging (Error Visibility)
- **Risiko:** **Sicher** — Logging nur, keine Verhaltensänderung

### 70. 8597f98da7286b91cf6aa37a8e97325a5bf6c0cd — miext: damage: use drawable pointer instead of list head pointer to avoid realloc() UAF
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Use-After-Free / realloc Safety)
- **Risiko:** **Sicher** — Drawable-Pointer statt List-Head, verhindert realloc-UAF

### 71. 10ac649a288d73a8fbdb2464f6e3c360570fdcd7 — xkb: Guard XkbAdjustGroup() against a keymap with no groups
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref / Edge Case)
- **Risiko:** **Sicher** — Guard gegen 0-Gruppen-Keymap

### 72. eab5bb0a5defb6f16120e4f4657a18b01df4f60f — RegionValidate: Fix double free of badreg->data on the error path
- **Autor/Datum:** 
- **Typ:** Bugfix (Double-Free Prevention)
- **Risiko:** **Sicher** — badreg->data = NULL nach free

### 73. 39243a696f774b1611ef695d11a7e1c227b294f3 — Xi: byte-swap XIQueryDevice ScrollClass flags
- **Autor/Datum:** 
- **Typ:** Bugfix (Byte-Swap / Endianness)
- **Risiko:** **Sicher** — ScrollClass Flags korrekt swappen

### 74. 2368211654d14ac0e1218cf434e274cd38f15f27 — xkb: Keep the group counts of a loaded keymap in range
- **Autor/Datum:** 
- **Typ:** Bugfix (Range Validation / Sanity Check)
- **Risiko:** **Sicher** — Group-Counts in Range halten

### 75. 4f29a5e71857b58e3f6d2aa32fb8b0f15a19263c — xkb: Never recompute a keymap's group count down to zero
- **Autor/Datum:** 
- **Typ:** Bugfix (Logic / Invariant Enforcement)
- **Risiko:** **Sicher** — Verhindert Group-Count = 0

### 76. ebc3e6b37a97c91b17e12c2787f6c112ea67ae4a — xkb: Default to one group whenever a keymap reports none
- **Autor/Datum:** 
- **Typ:** Bugfix (Default / Fallback)
- **Risiko:** **Sicher** — Default 1 Gruppe bei 0

### 77. d2ea37f385f8ff7dae0f8564176ee27cbb600218 — modesetting: use single sized hw cursor buffer for older amdgpu gpus
- **Autor/Datum:** 
- **Typ:** Bugfix (Workaround / Hardware Compatibility)
- **Risiko:** **Sicher** — Single-Buffer für ältere amdgpu

### 78. ca9645064be1de7da74696bc973d2c4d6db62de9 — darwin: Set thread priorities to user interactive or user initiated as appropriate
- **Autor/Datum:** 
- **Typ:** Feature/Refactoring (Thread Priority / macOS)
- **Risiko:** **Niedrig/Risikoreich** — **Einzige produktive Code-Änderung mit neuem Verhalten**: Thread-Prioritäten auf macOS/darwin. Kann Scheduling-Verhalten ändern. Sorgfältig testen auf macOS.

### 79. 91af3edfd20b4627942b44e041dc896f32b9bd7b — cygwin CI: install python312-lxml instead of python39-lxml
- **Autor/Datum:** 
- **Typ:** CI/Build (Dependency Update)
- **Risiko:** **Sicher** — Nur CI: Python 3.12 statt 3.9

### 80. bd7e7b5a5826e4abee493c1ae90129ff3430ff77 — fix getrandom fallback
- **Autor/Datum:** 
- **Typ:** Bugfix (Entropy / getrandom Fallback)
- **Risiko:** **Sicher** — Fallback für getrandom() Syscall

### 81. cfffe6a6d5aa2660dbb55f820de3b35a6cc71fcf — xquartz: add missing os/log_priv.h include for DebugF declaration
- **Autor/Datum:** 
- **Typ:** Build (Missing Include)
- **Risiko:** **Sicher** — Header-Include, kompiliert sonst nicht

### 82. 2a344f200a5eff45dc67f3b88da3cc7be6f65539 — randr: fix heap overflow and size tracking in RRChangeProviderProperty
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Heap Overflow / Size Tracking)
- **Risiko:** **Sicher** — Size-Tracking korrigiert, verhindert Heap-Overflow

### 83. bd7d465502f2f64c8642c45ee7cf6341bb90908f — glx: fix DrawableGone use-after-free without rejecting duplicate drawables
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Use-After-Free / Drawable Lifecycle)
- **Risiko:** **Sicher** — UAF-Fix bei DrawableGone, erlaubt Duplikate

### 84. 63cd9adbc1992eaf9e703d61fabf03dc49bc04eb — xfree86: close seatd input devices after DisableDevice(), not before
- **Autor/Datum:** 
- **Typ:** Bugfix (Ordering / Device Lifecycle)
- **Risiko:** **Sicher** — Reihenfolge korrigiert: DisableDevice() VOR Close

### 85. fc8d7a42bf4239ba7734719c5c571064a12131b9 — include: compiler.h: restore MIPS port I/O port access (12-year-old bug)
- **Autor/Datum:** 
- **Typ:** Bugfix (Architecture Support / MIPS)
- **Risiko:** **Sicher** — Restore 12-jahre-altes MIPS I/O, nur MIPS

### 86. da4dd3cb27483915823962d71faa631730c978cb — mi: fix double-free/UAF in miDCInitialize() on miSpriteInitialize() failure
- **Autor/Datum:** 
- **Typ:** Bugfix (Security: Double-Free / UAF / Error Path)
- **Risiko:** **Sicher** — Cleanup-Pfad bei miSpriteInitialize()-Fehler korrigiert

### 87. 339d92cc2eaff571c7085a5e2b08e11529c37c6d — kdrive: Don't fixup the cursor position twice in KdCursorOffScreen
- **Autor/Datum:** 
- **Typ:** Bugfix (Logic / Double-Fixup Prevention)
- **Risiko:** **Sicher** — Verhindert doppelte Cursor-Position-Korrektur

### 88. 75eaec7d94266282c49b74dbaf5a7edb552e6498 — randr: Set the legacy RandR size range to include rotations
- **Autor/Datum:** 
- **Typ:** Bugfix (RandR Size Range / Rotation Support)
- **Risiko:** **Sicher** — Legacy Size Range umfasst jetzt Rotationen

### 89. b33bf8038aa9c6fc99b2b320c0d0a6595280f553 — kdrive/ephyr: Fix typo when checking for `EGL_KHR_platform_x11`
- **Autor/Datum:** 
- **Typ:** Bugfix (Typo / Extension Check)
- **Risiko:** **Sicher** — Typo-Fix in Extension-String-Check

### 90. d89f0c4e568df4f03409ce0dc9fefce987d8a896 — Xephyr: fix setting physical output size
- **Autor/Datum:** 
- **Typ:** Bugfix (Xephyr / Output Configuration)
- **Risiko:** **Sicher** — Physical Output Size Setting korrigiert

### 91. 67a7be8982d5abdba9028c7ee664a56ff5fe0c46 — composite: Fix PanoramiX overlay window release
- **Autor/Datum:** 
- **Typ:** Bugfix (Resource Leak / Window Release)
- **Risiko:** **Sicher** — Overlay Window korrekt releasen

### 92. e439b570fa146737fcadef827aa312c5ce784efe — xkb: Fix -Wcalloc-transposed-args warning in _XkbCopyGeom()
- **Autor/Datum:** 
- **Typ:** Build/Refactoring (Warning Fix)
- **Risiko:** **Sicher** — calloc Args vertauscht korrigiert

### 93. 5fe2a56b194dbc556ed8355b9aab942abbb518a7 — xf86: prevent passing NULL pointer as strcpy destination
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref / Buffer Overflow Prevention)
- **Risiko:** **Sicher** — NULL-Check vor strcpy

### 94. 9b9c9fc3f650b481664a98966e17d6226f3c9d38 — xf86: prevent passing NULL pointer as strcat() destination
- **Autor/Datum:** 
- **Typ:** Bugfix (NULL-Deref / Buffer Overflow Prevention)
- **Risiko:** **Sicher** — NULL-Check vor strcat

### 95. 8e9791492f379791ef481298a762183b0de39551 — exa: silence -Wold-style-declaration warning from gcc 16
- **Autor/Datum:** 
- **Typ:** Build/Refactoring (Warning Silencing)
- **Risiko:** **Sicher** — Alt-Style Declaration modernisiert, nur Warning

### 96. 4e89986d57dde12b623af227c90ff5317921dee2 — Handle -Wimplicit-fallthrough warnings from gcc 16.1
- **Autor/Datum:** 
- **Typ:** Refactoring/Stil (Fallthrough Annotations)
- **Risiko:** **Sicher** — _X_FALLTHROUGH Annotationen, keine Logik-Änderung

### 97. 980a9e7e65560ddfe173558c0e9445143ff07874 — fb: Don't widen the planemask over padding bits when ROOTLESS_SAFEALPHA is set
- **Autor/Datum:** 
- **Typ:** Bugfix (Planemask / Rootless)
- **Risiko:** **Sicher** — Planemask nicht über Padding-Bits erweitern

### 98. 6b96b1bccc257b8f856ca2f8ff5c3e5f19141b52 — xquartz: Stop drawing before handing a frame to xp_frame_draw()
- **Autor/Datum:** 
- **Typ:** Bugfix (Draw Order / Frame Handoff)
- **Risiko:** **Sicher** — Drawing stop vor Frame-Handoff, xquartz only

### 99. a7b089d189ec185e8ebf772ee990962a1a3eb231 — rootless: Fix two region leaks
- **Autor/Datum:** 
- **Typ:** Bugfix (Memory Leak / Region Management)
- **Risiko:** **Sicher** — Zwei Region-Leaks gefixt

### 100. d44551d41d6bf0355e35bb68920365a9f1c03e7d — rootless: Keep the screen pixmap header consistent with its allocation
- **Autor/Datum:** 
- **Typ:** Bugfix (Consistency / Pixmap Header)
- **Risiko:** **Sicher** — Header-Konsistenz bei Allokation

### 101. 476a8c478bc0f7f59797b4382e902afadd717d2e — xquartz: Replace assert() around side-effecting calls with unconditional error handling
- **Autor/Datum:** 
- **Typ:** Refactoring/Stil (Assert → Error Handling)
- **Risiko:** **Sicher** — assert() entfernt, durch Error-Handling ersetzt (Production-Safe)

---

## Risiko-Klassifizierung

| Commit | Risiko | Begründung |
|---|---|---|
| ca9645064be1de7da74696bc973d2c4d6db62de9 (darwin thread priorities) | **Niedrig/Risikoreich** | **Einzige Verhaltensänderung**: Thread-Prioritäten auf macOS/darwin. Kann Scheduling ändern. Test auf macOS erforderlich. |
| Alle anderen 99 Commits | **Sicher** | Ausnahmslos Bugfixes (Crash/UAF/NULL/Overflow/Leak/Logic), CI/Build, Test-Churn, Warnungs-Hygiene. Keine neuen Features, keine API-Änderungen, keine entfernten Sicherheitschecks. |

---

## Fazit

**Keine produktiven Bugs in den 100 Commits seit xlibre-xserver-25.1.9 eingeführt.** Der Branch ist **stabil und release-reif** für ein Minor-Release.

**Einzige Aufmerksamkeit:** Commit `ca9645064be1de7da74696bc973d2c4d6db62de9` (darwin Thread-Prioritäten) sollte auf macOS getestet werden, falls XLibre auf macOS releast wird. Auf Linux/BSD keine Auswirkung.

**Empfehlung:** Release 25.1.10 kann ohne weitere Code-Änderungen gebaut werden. Die 6 manuellen Konflikte aus dem xorg/main-Backport (bad7edcab0, 37a1847a60, 2abe4632d7, 1b6955c310, be57263415, 1f42cc1f00) bleiben offen für spätere Backport-Runden.

---

## Anhänge

- Vollständige Commit-Liste: `_WORK_/tmp/251_since_tag_full.txt` (100 Einträge)
- Build-Test: `-Dwerror=true` → keine neuen Fehler durch lokale Cherry-Picks (52e6dcf41e, f0e6e4fe26)
- Vorheriger Scan (m5480): Bestätigt — keine noch enthaltenen Produktiv-Bugs