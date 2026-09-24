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
