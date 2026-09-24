Title: "xserver: DIX_FOR_N_SCREENS — make self-contained (ternary statt MIN) als separater PR"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Defiant"
Created-By: "Enterprise"
Created: "2026-09-24T11:06:18Z"
Doc-Ref: "PR #3730"

Separater PR (nicht #3725): DIX_FOR_N_SCREENS in dix/screenint_priv.h (master, via #3728 gemerged) soll ohne MIN auskommen (MIN nur via os/mathx_priv.h sichtbar). Fix: 'int walkStop = MIN(start+num, screenInfo.numScreens);' -> MIN-free (Kurzschluss-Ternary), besser unsigned walkStop (Konsistenz mit unsigned walkScreenIdx), und den kopierten 'all screens'-Doc-Kommentar an start+n-Limit-Semantik anpassen. Signatur unveraendert lassen (#3725 nutzt es). Eigener, NACHHER ENTSORGBARER starfleet-Worktree: 'starfleetctl worktree add _WORK_/xserver-master/sources/xlibre/xserver <name>' (KORREKTER Repo-Pfad!), toplevel/dest verifizieren, Primär-Clone passiv. Nach CI-Gruen: Enterprise bot-review + danach worktree remove.

PR #3730 created: https://github.com/X11Libre/xserver/pull/3730
Rebased onto current master after #3725 merge (force-pushed wt/task-dix-for-n-screens)
All CI checks GREEN - Enterprise bot-review PASS
Worktree removed: _WORK_/xserver-master/sources/xlibre/xserver task-dix-for-n-screens

- 2026-09-24T12:19:19Z Enterprise: completed
