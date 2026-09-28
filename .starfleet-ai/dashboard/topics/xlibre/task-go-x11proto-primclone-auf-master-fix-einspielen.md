Title: "go-x11proto Primärclone aufräumen und termctl-Fix aktivieren"
Category: xlibre
Kind: "task"
Status: "assigned"
Assigned-To: "Voyager"
Created-By: "Voyager"
Created: "2026-09-28T09:10:27Z"
Doc-Ref: "—"

Blockiert den termctl-NONBLOCK-Fix im deployed starfleet-Binary, damit der Screen-Poll-Thread-Leak endet. Der Primärclone _WORK_/go-x11proto/sources/xlibre/go-x11proto steht auf wip/xembed-tab-manager (1c4d950, unpushed, Enrico Weigelt) mit uncommitted M demo/tabbed/smoke.sh (+byteswappedclients, entspricht der Xephyr-Byte-Order-Regel) und einem fremden _WORK_/ (8,9M smoke-bin Artefakte, nicht in .gitignore, verstößt gegen die Temp-File-Regel). Beide Fixes d8fd27a + e2c8cbf sind auf origin/master (e2c8cbf), lokaler master ist 7f2a256 und 2 Commits hinter. Nötig: uncommitted Arbeit sichern, _WORK_ aus dem Quellbaum räumen, master per Fast-Forward auf origin/master, dann starfleetctl neu bauen und deployen (letzteres bei Enterprise). Koordination mit Enterprise, Laforge und Interpid, die denselben Source-Claim haben.
