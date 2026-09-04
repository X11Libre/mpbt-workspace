Title: "xlibre: drivers: finish \"ci: bump action-build-driver to v0.4.0\" PRs"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "Voyager"
Created-By: "TestShip"
Created: "2026-09-04T16:18:45Z"
Doc-Ref: "—"

1. Bei den Treibern sind noch etliche PRs zum action-build-driver v0.4.0 offen, die in machen lanes brechen. Analysieren, reparieren und wenn alles grün mergen.
 
2. Alle Treiber sollen v0.4.0 der action benutzen.

3. Außerdem haben wir noch einige PRs zu "configure.ac: re-add AC_USE_SYSTEM_EXTENSIONS" offen (sub-topic zum mpbt container support - hier sind einige treiber-bugs bzgl. asprintf() aufgefallen) ... diese nach dem action update rebasen, durchbauen, fertigstellen und wenn grün mergen.

Aufgabe eigenständig abarbeiten. Board-Status stets aktuell halten (aktueller Stand soll jederzeit im Fleet-Board sichtbar sein). Wenn fertig report an McKinley und Starfleet-Report einstellen.

- 2026-09-04T16:20:38Z Voyager: began work

- 2026-09-04T16:20:49Z Voyager: Status: 6/6 v0.4.0-Bump-PRs gemerget (mouse#17, mach64#12, ati#35, nouveau#22, qxl#21, amdgpu#68). asprintf-PRs auf neuen Master rebased: mouse#15 MERGED, mach64#10/ati#33/qxl#19 gruen auf FreeBSD (VM-Flakes auf NetBSD/DragonFly), MERGEABLE, warten auf Merge.
