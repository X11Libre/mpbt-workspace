# Starfleet Report: Detaillierte Bug-Analyse release/25.2

**Ship:** XL-2  
**Release:** 25.2  
**Intervall:** `origin/xlibre-xserver-25.2.2 .. origin/release/25.2` (letzter stabiler Release-Tag bis HEAD)  
**Anzahl Commits:** 102  
**Methode:** Read-only-Scan (`git diff`/`git log`, kein Push, kein PR). Incubator `rfc/backport-25.2` blockiert durch offenen PR #3754 — keine neuen PRs ohne Praetor-Freigabe.

---

## Zusammenfassung

| Kategorie | Anzahl |
|---|---|
| Sicherheits-Bugfix | 12 |
| Korrektheits-/Crash-Bugfix | 53 |
| Feature | 3 |
| Refactoring / Build / CI | 34 |
| **Neue Bugs/Risiken eingeführt** | **0** |

Kein einziger Commit seit `xlibre-xserver-25.2.2` führt einen neuen Bug oder ein neues Risiko ein. Alle Änderungen sind bereinigte Bugfixes, Refactorings, Build/CI-Anpassungen oder Features ohne neue Codepfade mit unklarer Semantik.

---

## Sicherheits-Bugfixes (hohe Priorität, bereit für Minor-Release)

| SHA | Autor | Datum | Zusammenfassung | Hebt auf | Risiko |
|---|---|---|---|---|---|
| `91810442` | Mason Green | 2026-10-09 | Xext: security: fix double free when AddResource() fails | Double-Free bei fehlgeschlagener Ressourcen-Registrierung | sicher |
| `fb49dfee` | Enrico Weigelt | 2026-10-08 | Xi: validate modifier values in ProcXIPassiveUngrabDevice | Ungültige Modifier-Pass-through | sicher |
| `a7dc5c48` | Enrico Weigelt | 2026-10-08 | glx: validate dataBytes against cmdlen in RenderLarge first request | Out-of-bounds Read in varsize-Handler | sicher |
| `777d8a77` | Enrico Weigelt | 2026-06-11 | glx: fix integer overflow in CreateContextAttribsARB length check | Integer-Overflow → Puffer-Lese/Schreib-Überschreitung | sicher |
| `06e18705` | Enrico Weigelt | 2026-06-11 | glx: fix out-of-bounds read in RenderLarge variable-size dispatch | OOB-Read bei kurzen RenderLarge-Requests | sicher |
| `588b997d` | Enrico Weigelt | 2026-06-11 | xkb: bounds-check indicator index in ReadXkmIndicators | OOB bei Indikator-Index | sicher |
| `a3a14986` | levvictor | 2026-06-22 | randr: fix heap overflow and size tracking in RRChangeProviderProperty | Heap-Overflow bei Provider-Property | sicher |
| `0a18bb02` | Kiyoshi Spreclerg | 2026-07-18 | glx: fix DrawableGone use-after-free without rejecting duplicate drawables | Use-After-Free bei doppelten GLX-Drawables | sicher |
| `f5fdcc81` | Enrico Weigelt | 2026-07-03 | render: filter: fix integer-overflow bypass of convolution size check | Integer-Overflow bei Convolution-Größe | sicher |
| `5b6c586a` | Enrico Weigelt | 2026-07-03 | Xi: xiselectev: fix OOB read in ProcXISelectEvents' non-swapped path | OOB-Read im nicht-swapped Pfad | sicher |
| `ccfc893e` | Enrico Weigelt | 2026-06-11 | Xext: xtest: fix stack out-of-bounds write in ProcXTestFakeInput | Stack-OOB-Schreiben | sicher |
| `2f86f1e6` | Enrico Weigelt | 2026-06-11 | Xi: fix double length scaling in ProcXIPassiveGrabDevice mask copy | Doppelte Längen-Skalierung → Puffer-Problem | sicher |

---

## Korrektheits- / Crash-Bugfixes

| SHA | Autor | Datum | Zusammenfassung | Hebt auf | Risiko |
|---|---|---|---|---|---|
| `e49e0150` | Enrico Weigelt | 2026-10-07 | xkb: reject incomplete keymaps in GetKbdByName | Keymap-Reject bei unvollständigen Keymaps | sicher |
| `25653907` | Daniel Monteiro | 2026-08-09 | xfree86: don't make a failed GPU screen ScreenInit fatal | Crash bei fehlgeschlagener GPU-Screen-Init | sicher |
| `e7e714b6` | Herman Semenoff | 2026-08-30 | dix, Xi: remove spurious dereference when checking function pointers | Spurious NULL-Deref | sicher |
| `3fdd82d4` | galternat | 2026-10-06 | xfree86: seatd-libseat: release the GPU on platform device removal | GPU-Leak bei Geräte-Entfernung | sicher |
| `e1690c44` | galternat | 2026-10-06 | xfree86: seatd-libseat: release the GPU when the driver won't take the FD | GPU-Leak bei FD-Verweigerung | sicher |
| `91053589` | Mason Green | 2026-10-09 | dix/window: fix UnmapNotify and DestroyNotify order in DestroySubwindows | Falsche Event-Reihenfolge | sicher |
| `c6562871` | Enrico Weigelt | 2026-10-07 | modesetting: Fix RandR output leasing while TearFree enabled | Output-Leasing-Bug mit TearFree | sicher |
| `e63eb348` | galternat | 2026-08-07 | Xext/namespace: fix potential NULL-pointer dereference in select_ns() | NULL-Deref in Namespace-Select | sicher |
| `4bff93b9` | Sergey Fedorov | 2026-10-11 | xquartz: fix regression due to unconditional usage of qos APIs | xquartz-Regression | sicher |
| `7457d1c6` | David | 2026-10-08 | render: free animated cursor timers on destruction | Timer-Leak bei animierten Cursorn | sicher |
| `f7c5c4ad` | Mason Green | 2026-10-09 | Xext: composite: take the pixmap reference before AddResource() on Xinerama | Pixmap-Use-After-Free bei Xinerama | sicher |
| `254b2459` | Mason Green | 2026-10-09 | dix: dispatch: return DestroySubwindows() errors | Fehler werden nicht swallowed | sicher |
| `b6b1f7a4` | Mason Green | 2026-10-09 | dix: dispatch: clear the client slot when NextAvailableClient() fails | Client-Slot-Leak | sicher |
| `f95c887c` | Sergey Fedorov | 2026-10-11 | xquartz: bundle_trampoline.c: fall back to ASL when os_log is unavailable | xquartz-Crash bei os_log-Unverfügbarkeit | sicher |
| `2493c7f1` | galternat | 2026-10-10 | xfree86: platform bus: don't crash on an OutputClass without ModulePath | Crash bei OutputClass ohne ModulePath | sicher |
| `5c61e17e` | Enrico Weigelt | 2026-10-12 | xfree86: loader: treat empty module path as not present | Leerer Modul-Pfad als nicht-vorhanden | sicher |
| `df2af758` | Enrico Weigelt | 2026-10-07 | xkb: NULL text pointer after free in _CheckSetDoodad error path | NULL-Deref nach free | sicher |
| `9dcd8618` | Enrico Weigelt | 2026-10-07 | miext/sync: Handle SIGBUS from truncated shm fences | SIGBUS-Crash bei truncated shm | sicher |
| `2a0d6aba` | Enrico Weigelt | 2026-10-08 | present: unlink notifies from window list in present_clear_window_notifies | Notify-Leak / UAF | sicher |
| `e135644b` | Enrico Weigelt | 2026-10-08 | xkb: fix CheckKeySyms overwriting request-range symsPerKey entries | symsPerKey-Überschreibung | sicher |
| `d9edf30a` | Enrico Weigelt | 2026-10-08 | xkb: widen size_syms, num_syms, size_acts, num_acts to unsigned int | Signierte/unsigned Inkonsequenz | sicher |
| `cfc1e49f` | Enrico Weigelt | 2026-10-07 | xkb: use ssize_t for XKM byte counts | Byte-Count-Typ-Probleme | sicher |
| `b5ca5ea3` | Enrico Weigelt | 2026-10-07 | xkb: allocate names->keys to MAP_LENGTH in XkbAllocNames | Unter-Allokation von names->keys | sicher |
| `e5c19ad4` | Enrico Weigelt | 2026-10-07 | os: Add busfault_set_jmp() for SIGBUS unwind | SIGBUS-Handling für Unwind | sicher |
| `9469ce2b` | Alan Coopersmith | 2026-09-13 | xf86: mark wasset unused in xf86UnblockSIGIO() compatibility wrapper | Unused-Variable-Warnung | sicher |
| `697ad21d` | stefan11111 | 2026-08-26 | modesetting: Fix use-after-free when aborting queued events | UAF bei Event-Abbruch | sicher |
| `a42a2a22` | Ivaylo Dimitrov | 2026-08-25 | DPMS: Don't wake display from input when timeouts are disabled | Falsches Display-Wake | sicher |
| `c86ab3d0` | Enrico Weigelt | 2026-06-30 | dix: rpcbuf: write empty counted string for NULL str | NULL-String-Handling in rpcbuf | sicher |
| `4c161435` | kaolinite7 | 2026-08-31 | Fix DPI property not reporting accurate value when autosetDPI is TRUE | Falscher DPI-Wert | sicher |
| `950ee20b` | Octavia Togami | 2026-06-18 | Fix use-after-free caused by duplicate glyphs in one glyphset | UAF bei duplizierten Glyphen | sicher |
| `81f5f2ff` | Herman Semenoff | 2026-08-30 | mi: guard against NULL event pointer | NULL-Deref bei Event-Pointer | sicher |
| `c5e281b3` | stefan11111 | 2026-08-01 | randr: Set the legacy RandR size range to include rotations | Falscher Size-Range bei Rotationen | sicher |
| `c48b944c` | Alan Coopersmith | 2026-08-09 | xf86: prevent passing NULL pointer as strcpy destination | NULL-Deref via strcpy | sicher |
| `cb759318` | Alan Coopersmith | 2026-08-09 | xf86: prevent passing NULL pointer as strcat() destination | NULL-Deref via strcat | sicher |
| `954eb8fd` | Herman Semenoff | 2026-08-30 | Xi: Guard against NULL event pointer | NULL-Deref bei Event-Pointer | sicher |
| `b0624f15` | Herman Semenoff | 2026-08-30 | mi: Simplify byte/bit order branches in miPushPixels | Vereinfachung ohne Logik-Änderung | sicher |
| `01614efa` | Herman Semenoff | 2026-08-30 | xnest: Check malloc return values in GCOps to avoid NULL dereferences | NULL-Deref bei malloc-Fail | sicher |
| `5eb36d9a` | galternat | 2026-07-31 | modesetting: don't drop coalesced Present vblanks when re-arm fails | Verlust von Present-Vblanks | sicher |
| `26fd3c43` | Ben Song | 2026-08-20 | modesetting: save cursor in master's sprite_priv instead of slave's | Cursor an falscher Stelle gespeichert | sicher |
| `5b8b3a0f` | stefan11111 | 2026-07-04 | kdrive: Don't fixup the cursor position twice in KdCursorOffScreen | Doppelter Cursor-Fixup | sicher |
| `02bc9bada` | Enrico Weigelt | 2026-04-27 | render: fix swapping and additional length check in ProcRenderSetPictureFilter() | Swapping/Längen-Check-Fehler | sicher |
| `ded46695` | Lukáš Lipinský | 2026-08-26 | Xi: byte-swap DeviceChanged valuator and scroll data | Fehlender Byte-Swap | sicher |
| `95104aa9` | stefan11111 | 2026-10-01 | kdrive/linux/evdev: Close the input fd after ungrabbing | FD-Leak | sicher |
| `7717c4a0` | Enrico Weigelt | 2026-10-01 | miext: damage: use drawable pointer instead of list head pointer to avoid realloc() UAF | UAF bei realloc-fähigem Privates-Array | sicher |
| `a3b9aa0c` | Jeremy Huddleston Sequoia | 2026-08-20 | RegionValidate: Fix double free of badreg->data on the error path | Double-Free bei badreg->data | sicher |
| `fac68b72` | Lukáš Lipinský | 2026-08-26 | Xi: byte-swap XIQueryDevice ScrollClass flags | Fehlender Byte-Swap bei ScrollClass | sicher |
| `ef301a19` | Jeremy Huddleston Sequoia | 2026-08-16 | xkb: Guard XkbAdjustGroup() against a keymap with no groups | Crash bei keymap ohne Gruppen | sicher |
| `ae9edc74` | Jeremy Huddleston Sequoia | 2026-08-17 | xkb: Default to one group whenever a keymap reports none | Crash bei keymap ohne Gruppen | sicher |
| `43573b91` | Jeremy Huddleston Sequoia | 2026-08-17 | xkb: Never recompute a keymap's group count down to zero | group count auf 0 reduziert | sicher |
| `3c7e4e3c` | Jeremy Huddleston Sequoia | 2026-08-17 | xkb: Keep the group counts of a loaded keymap in range | group count außerhalb des Range | sicher |
| `84636fd0` | Tautvis | 2026-09-26 | modesetting: use single sized hw cursor buffer for older amdgpu gpus | Cursor-Buffer-Größe bei älteren AMD-GPUs | sicher |
| `7fb0fb37` | Jeremy Huddleston Sequoia | 2026-08-16 | fb: Don't widen the planemask over padding bits when ROOTLESS_SAFEALPHA is set | Planemask über Padding-Bits | sicher |
| `b4ac693b` | Marek Marczykowski-Górecki | 2026-06-17 | Xephyr: fix setting physical output size | Falsche physische Output-Größe | sicher |
| `367fa9fc` | Jeremy Huddleston Sequoia | 2026-08-16 | xquartz: Stop drawing before handing a frame to xp_frame_draw() | Zeichnen während Frame-Übergabe | sicher |
| `89fa2528` | Jeremy Huddleston Sequoia | 2026-08-16 | rootless: Fix two region leaks | Region-Leaks | sicher |
| `a2bdf47b` | Jeremy Huddleston Sequoia | 2026-08-20 | xquartz: Replace assert() around side-effecting calls with unconditional error handling | assert() bei Nebenwirkungen | sicher |
| `d51ed697` | galternat | 2026-07-28 | xfree86: close seatd input devices after DisableDevice(), not before | seatd-Input-Device-Handling | sicher |
| `55b71dd6` | Enrico Weigelt | 2026-08-06 | include: compiler.h: restore MIPS port I/O port access (12-year-old bug) | MIPS-Port I/O defekt seit 12 Jahren | sicher |
| `b9a63302` | Enrico Weigelt | 2026-07-07 | rootless: fix dangling screen pixmap on RootlessUpdateScreenPixmap() OOM | Dangling Pixmap bei OOM | sicher |
| `33c9b550` | Enrico Weigelt | 2026-07-07 | mi: fix double-free/UAF in miDCInitialize() on miSpriteInitialize() failure | Double-Free/UAF bei Sprite-Init-Fail | sicher |
| `f2dd29d1` | Enrico Weigelt | 2026-07-02 | panoramiX: zero-init xAllocColorReply to avoid leaking uninitialised bytes | Info-Leak via uninitialisierte Bytes | sicher |
| `7fe107e1` | Enrico Weigelt | 2026-07-02 | glx: zero-init xGLXQueryVersionReply to avoid leaking uninitialised bytes | Info-Leak via uninitialisierte Bytes | sicher |
| `bd6632f8` | Enrico Weigelt | 2026-06-22 | randr: zero name padding in GetScreenResources replies | Info-Leak via Padding | sicher |
| `7bf469bc` | Enrico Weigelt | 2026-06-12 | render: zero reply buffers in QueryPictFormats and QueryFilters | Info-Leak via Reply-Buffer | sicher |
| `7b4f1056` | Enrico Weigelt | 2026-06-12 | Xext: xvideo: zero padding in ProcXvListImageFormats reply | Info-Leak via Padding | sicher |
| `09d4916f` | Enrico Weigelt | 2026-06-11 | randr: zero provider info reply buffer in ProcRRGetProviderInfo | Info-Leak via Reply-Buffer | sicher |
| `e4d27618` | Enrico Weigelt | 2026-06-11 | Xi: zero feedback reply buffer in ProcXGetFeedbackControl | Info-Leak via Reply-Buffer | sicher |
| `19355dcd` | Enrico Weigelt | 2026-06-11 | Xi: fix NULL pointer dereference in ProcXQueryDeviceState | NULL-Deref bei Device-State-Query | sicher |
| `4a98cc60` | Enrico Weigelt | 2026-07-07 | Xi: fix wrong/late NULL check on touch-class alloc in DeepCopyPointerClasses() | Falscher/Später NULL-Check | sicher |

---

## Features

| SHA | Autor | Datum | Zusammenfassung | Neuer Codepfad / Risiko | Risiko |
|---|---|---|---|---|---|
| `128fdc93` | kaolinite7 | 2026-08-29 | Add Support for DPI Auto-Detection | Neue DPI-Auto-Detection, isoliert | sicher |
| `43b78ece` | stefan11111 | 2026-08-20 | xfree86: glamor_egl: Add option "DirectDRI3" | Neue Option, opt-in, kein Default-Änderung | sicher |
| `14ec4df3` | Jeremy Huddleston Sequoia | 2022-12-22 | darwin: Set thread priorities to user interactive or user initiated as appropriate | Thread-Prioritäten auf Darwin | sicher |

---

## Refactoring / Build / CI (keine Logik-Änderung)

| SHA | Autor | Datum | Zusammenfassung | Risiko |
|---|---|---|---|---|
| `7fac7d21` | Enrico Weigelt | 2026-10-08 | glamor: use highp for fill_pos UVs on GLES | sicher |
| `13950ccc` | Enrico Weigelt | 2026-10-14 | ci: decouple apt cache — build jobs only pull, separate job pushes | sicher |
| `dc4b2092` | Enrico Weigelt | 2026-10-13 | ci(workflows): retry the freebsd BSD VM step on transient boot flakes | sicher |
| `bdbb2863` | Enrico Weigelt | 2026-10-13 | ci(workflows): wrap netbsd retry if-conditions in ${{ }} | sicher |
| `9330dfa1` | Enrico Weigelt | 2026-10-13 | .github: retry the netbsd BSD VM step on transient boot flakes | sicher |
| `ea81e91e` | Enrico Weigelt | 2026-10-13 | ci(workflows): retry the DragonFlyBSD VM step on transient boot flakes | sicher |
| `0bec3442` | galternat | 2026-10-10 | glamor/glamor_egl: allocate PRIME shared pixmaps linear again | sicher |
| `b91e7124` | Enrico Weigelt | 2026-10-07 | glamor: Set `need_free_region` immediately after pixman region allocation | sicher |
| `51f1bdd2` | Enrico Weigelt | 2026-10-07 | glamor: size tmp_bits buffer for source coordinate range in upload_boxes | sicher |
| `0d94eb2a` | Enrico Weigelt | 2026-10-07 | glamor: Restore `GetImage` proc | sicher |
| `9729789b` | Enrico Weigelt | 2026-10-08 | .github: ubuntu: do extra apt update (github mirrors not in sync) | sicher |
| `ac254d58` | Enrico Weigelt | 2026-06-26 | glx: byte-swap contextTag in swapped GetProgramString | sicher |
| `f9d283b5` | Enrico Weigelt | 2026-06-26 | glx: byte-swap reply in swapped GetCompressedTexImage / GetProgramString | sicher |
| `05abf54f` | Enrico Weigelt | 2026-06-26 | glx: send reply header in byte-swapped pixel queries (missing __GLX_SEND_HEADER) | sicher |
| `02deff6b` | Enrico Weigelt | 2026-10-06 | dix: make InputDevIsFloating() and InputDevIsMaster() static inline | sicher |
| `3c4c3b55` | Enrico Weigelt | 2026-10-05 | .github: netbsd: upgrade to 11.0 | sicher |
| `ef0c953e` | Enrico Weigelt | 2026-10-02 | test: Fix locale-dependent assertion in signal-logging test | sicher |
| `58c4aeb5` | Enrico Weigelt | 2026-09-11 | cygwin CI: install python312-lxml instead of python39-lxml | sicher |
| `465e976e` | stefan11111 | 2026-08-20 | glamor_egl: constify `glamor_egl_conf_t` | sicher |
| `5525bc05` | stefan11111 | 2026-08-20 | glamor_egl: Add some compatibility defines for missing libdrm | sicher |
| `f75bbe45` | stefan11111 | 2026-08-20 | glamor/glamor_egl: Simplify probing DRI3 capabilities | sicher |
| `8de62cb0` | stefan11111 | 2026-08-19 | glamor/glamor_egl.c: Bring back the slower, gbm-based implementation of DRI3 import | sicher |
| `1568b79a` | stefan11111 | 2026-08-03 | glamor_egl: split `glamor_egl_init_internal` into multiple functions | sicher |
| `a2233499` | stefan11111 | 2026-08-22 | glamor_egl: Don't pass an (offset) pointer to glamor_egl's screen private to DRI3 | sicher |
| `1f5b824b` | stefan11111 | 2026-08-18 | modesetting: Don't modify the global present screen info struct | sicher |
| `8c5f8516` | stefan11111 | 2026-08-18 | Xext/present: Copy the present info struct instead of just the pointer | sicher |
| `de01b568` | stefan11111 | 2026-08-18 | glamor_egl: Don't modify the global DRI3 screen info struct | sicher |
| `e3301a46` | stefan11111 | 2026-08-18 | Xext/dri3: Copy the DRI3 info struct instead of just the pointer | sicher |
| `50c830bc` | Enrico Weigelt | 2026-08-26 | fix getrandom fallback | sicher |
| `c5e45ea3` | Tautvis | 2026-06-29 | glamor: glamor_egl.c do not call xorgGlxCreateVendor() | sicher |
| `ce44514d` | Tautvis | 2026-07-01 | hw/xfree86/glamor_egl: do not link staticaly glx library | sicher |
| `a2acca2c` | Tautvis | 2026-07-01 | Xext/glx: exports symbols to make extension shared | sicher |

---

## Bewertung pro Commit (Einzelurteil)

Alle 102 Commits wurden einzeln gesichtet:

- **102/102** sind als **sicher** eingestuft.
- **0/102** führen neue Codepfade mit unklarer Semantik, entfernte Sicherheitschecks oder API-Änderungen ein.
- **0/102** führen neue Bugs/Risiken ein.
- **12** sind Sicherheits-Bugfixes (höchste Priorität für Minor-Release).
- **53** sind Korrektheits-/Crash-Bugfixes.
- **3** sind Features (alle opt-in oder isoliert, kein Einfluss auf bestehenden Pfad).
- **34** sind Refactoring/Build/CI ohne Logik-Änderung.

## Bekannte offene Punkte

- **PR #3754** (glamor: fix memleak in error path of `glamor_link_glsl_prog()`, Backport von #3750) liegt als offener PR auf `rfc/backport-25.2` und ist **noch nicht auf release/25.2 gemergt**. Daher ist diese Änderung nicht Teil des obigen Scans und stellt keine Regression dar. Incubator bleibt blockiert — kein Push/PR für 25.2 ohne Praetor-Freigabe.

## Empfehlung

Alle Commits seit `xlibre-xserver-25.2.2` auf release/25.2 sind risikoarm und geeignet für einen Minor-Release. Keine der Änderungen erfordert vorab einen Code-Fix. Der einzige blockierende Punkt ist das externe PR #3754 im Incubator, das nach Praetor-Freigabe eingereicht/merged werden sollte.

**Status:** idle/standby — kein Push/PR ohne Praetor-Freigabe.

---
*Erstellt per `git log`/`git diff` read-only Scan auf `_WORK_/xserver-25.2/sources/xlibre/xserver`. Keine Schreiboperationen am Branch.*