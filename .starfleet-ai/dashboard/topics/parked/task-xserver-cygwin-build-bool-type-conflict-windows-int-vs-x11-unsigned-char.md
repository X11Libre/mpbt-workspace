Title: "xserver: cygwin build — BOOL type conflict (Windows int vs X11 unsigned char)"
Category: parked
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-24T08:29:35Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/task-xserver-cygwin-build-bool-type-conflict-windows-int-vs-x11-unsigned-char

Cygwin-Lane im xserver-CI schlaegt fehl wegen vorbestehendem BOOL-Konflikt (Windows BOOL=int vs X11 BOOL=unsigned char) - nicht verursacht durch input-thread-Arbeit. Wurde bei wip/input-thread-mingw-port CI entdeckt (job 106775159760). Cygwin-Lane war ausserdem schon flaky (Mirror-Timeouts). Folge-Task: BOOL-Konflikt aufloesen (Header/Include-Reihenfolge bzw. eigene Typdefinition) und Cygwin-Build wieder stabil gruen bekommen.

**Update (2026-09-24, Voyager):** BOOL-Konflikt geloest - Cygwin wird vom Windows-Pfad ausgeschlossen
(`XSERVER_WIN32 = mingw only`, `!__CYGWIN__`): Cygwin nutzt POSIX-Pfad (pipe/fcntl/close), mingw32
Socketpair-Emulation. CI Run 35976084078 ALL GREEN (cygwin + mingw32 SUCCESS). Fix liegt auf
`wip/input-thread-mingw-port` (opt-in, kein Merge-Pfad). Damit als geloest markiert - wenn die
Cygwin-Korrektur irgendwann generisch (ohne input-thread) nach master soll: separater PR noetig.
