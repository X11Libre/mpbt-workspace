Title: "os.h: Analyse abgeschlossen — Subtasks bereit"
Category: active
Kind: "task"
Status: "analysis-done"
Assigned-To: "Saratoga"
Tags: "xlibre,sdk-cleanup,os.h"
Slug: os.h-analysis

## os.h Analyse (v0.1 — 313 Zeilen)

### MUSS PUBLIC BLEIBEN (von Treibern referenziert):

1. **XNFalloc / XNFcallocarray / XNFrealloc** (Zeilen 167-189)
   - inkl. Macros xnfalloc/xnfcalloc/xnfrealloc (Zeilen 93-99)
   - Verwendet von: intel, ati, neomagic, suncg3, mouse (xnfalloc)

2. **Xstrdup / XNFstrdup** (Zeilen 195-203)
   - inkl. Macros xstrdup/xnfstrdup (Zeilen 98-99)
   - Verwendet von: joystick (xstrdup), mouse (xnfstrdup)

3. **ErrorF** (Zeile 288-290)
   - Verwendet von JEDEM Treiber für Debug-Logging

4. **FatalError** (Zeilen 283-285)
   - Verwendet von: intel, ati/radeon, neomagic

5. **LogMessage** (Zeilen 272-273)
   - Verwendet von: intel (uxa)

6. **LogVMessageVerb / LogMessageVerb** (Zeilen 266-271)
   - Verwendet von: intel (indirekt), diverse

7. **GetTimeInMillis** (Zeile 138)
   - Verwendet von: intel, ati/radeon, viele weitere

8. **GetTimeInMicros** (Zeile 139)
   - Verwendet von: intel (sna_present)

9. **TimerSet / TimerFree / TimerCancel** (Zeilen 152-158)
   - TimerAbsolute/TimerForceOld-Flags (Zeilen 149-150)
   - OsTimerPtr/OsTimerCallback-Typedefs (Zeilen 143-147)
   - Verwendet von: intel (uxa, sna)

10. **SetNotifyFd / RemoveNotifyFd** (Zeilen 127-132)
    - Verwendet von: intel, ati/radeon

11. **OsRegisterSigWrapper** (Zeilen 210-211)
    - Verwendet von: intel (sna_accel)

12. **FlushCallback** (Zeile 220)
    - Verwendet von: intel, ati/radeon

13. **WriteToClient** (Zeilen 119-121)
    - Verwendet von: sis, sisusb, vmware (Xinerama/ctrl-Protokoll-Extensions)

14. **MessageType-Enum** (Zeilen 251-264)
    - Wird von Treibern als Argument für LogMessage/ErrorF verwendet

15. **System()** — deprecated inline (Zeilen 307-311)
    - Nur noch backwards-compat für xf86-video-intel

16. **Backwards-compat Macros** (Zeilen 296-299):
    LogVMessageVerbSigSafe, LogMessageVerbSigSafe, ErrorFSigSafe, VErrorF

### KANN/MUß NICHT PUBLIC BLEIBEN (nur xserver-intern):

17. **ReadFdFromClient** (Zeile 105)
    - Nur intern (DRI3, SHM, dix)

18. **IgnoreClient / AttendClient** (Zeilen 134-136)
    - Nur intern (dix, Xext/glx/sync/record)

19. **GetClientFd** (Zeile 217)
    - Nur intern (xselinux)

20. **PrivsElevated** (Zeilen 213-214)
    - Kein Treiber verwendet es

21. **TimeSinceLastInputEvent** (Zeile 223)
    - Kein Treiber verwendet es

22. **xorg_backtrace** (Zeile 292)
    - Kein Treiber verwendet es

23. **AdjustWaitForDelay** (Zeile 141)
    - Nur intern (dixfonts)

24. **NewClientPtr** (Zeile 91)
    - Nur xserver-intern

25. **SCREEN_SAVER_* / MAX_REQUEST_SIZE** (Zeilen 82-89)
    - Von Treibern nicht verwendet (MAX_REQUEST_SIZE ist Protokollkonstante)

26. **strlcpy / strlcat / strndup / reallocarray / timingsafe_memcmp**
    (Zeilen 227-248) — AC_REPLACE_FUNCS-Fallbacks
    - Von keinem Treiber direkt verwendet, können in privaten Header

Vorschlag weitere Schritte:
   A) Extraktion von Xprintf.h, alloc.h, logging.h, client-io.h,
      timer.h, notify-fd.h, sigwrapper.h aus os.h
   B) os.h wird dünner public Wrapper (include der neuen headers)
   C) Interne Nutzer migrieren auf neue private header
