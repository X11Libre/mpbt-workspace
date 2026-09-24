Title: "xserver: DIX_FOR_N_SCREENS — make self-contained (ternary statt MIN) als separater PR"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-24T11:06:18Z"
Assigned-To: "Defiant"
Doc-Ref: "—"
Slug: task-xserver-dix-for-n-screens-make-self-contained-ternary-statt-min-als-separater-pr

Separater PR (nicht #3725): DIX_FOR_N_SCREENS in dix/screenint_priv.h (master, via #3728 gemerged) soll ohne MIN auskommen (MIN nur via os/mathx_priv.h sichtbar). Fix: 'int walkStop = MIN(start+num, screenInfo.numScreens);' -> MIN-free (Kurzschluss-Ternary), besser unsigned walkStop (Konsistenz mit unsigned walkScreenIdx), und den kopierten 'all screens'-Doc-Kommentar an start+n-Limit-Semantik anpassen. Signatur unveraendert lassen (#3725 nutzt es). Eigener, NACHHER ENTSORGBARER starfleet-Worktree: 'starfleetctl worktree add _WORK_/xserver-master/sources/xlibre/xserver <name>' (KORREKTER Repo-Pfad!), toplevel/dest verifizieren, Primär-Clone passiv. Nach CI-Gruen: Enterprise bot-review + danach worktree remove.
