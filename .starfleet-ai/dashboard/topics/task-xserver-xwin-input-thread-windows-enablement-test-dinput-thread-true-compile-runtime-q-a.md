---
title: "xserver: xwin input_thread Windows enablement — test -Dinput_thread=true (compile + runtime Q/A)"
category: active
kind: "task"
status: "done"
assigned-to: "Voyager"
tags: "xserver,xwin,input-thread,ci"
---

**Ausgangslage (Analyse, verifiziert):** `input_thread` default `auto`; `include/meson.build:62-63`
erzwingt `false` für `windows + auto`; `-Dinput_thread=true` ohne `PTHREAD_MUTEX_RECURSIVE`
= harter Build-Fehler. Seit 2016 auf Windows deaktiviert (Commit `246b729df8`, Jon Turney:
Windows will Events an den fenster-erzeugenden Thread liefern). `ddxInputThreadInit()` (xwin)
steht korrekt unter `#if INPUTTHREAD`. Linux/glibc baut bereits mit `INPUTTHREAD=1`.

**CI-Test (Voyager, Branch `wip/test-input-thread-windows`, `-Dinput_thread=true`):**
- mingw32-ubuntu lane → **FAILED** (pthread-Feature `PTHREAD_MUTEX_RECURSIVE` in
  mingw-w64-Toolchain nicht sauber verfügbar) — bestätigt Turneys 2016-Bedenken.
- cygwin lane → **SUCCESS** (kompiliert + linkt, POSIX-Subsystem). Eingabe-Thread ist
  auf Cygwin grundsätzlich nutzbar.

**Konsequenz (Empfehlung):** `input_thread` **weiterhin per Default auf Windows deaktiviert**
lassen. Optionale Aufweichung nur für Cygwin/POSIX-artige Umgebungen denkbar — kein Code-Change
notwendig, kein Risiko für bestehende Builds. Der praktische Effekt einer Freischaltung auf
nativem Windows wäre ohnehin „kein Thread" (xwin ruft `InputThreadPreInit()` nicht auf).

**Verifikation:** GitHub-Actions-Run 35718780939 (mingw32-ubuntu rot, cygwin grün).