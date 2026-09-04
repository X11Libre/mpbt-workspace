Title: "xlibre: drivers: fix CI fails for action-build-driver version bumps"
Category: xlibre
Kind: "task"
Status: "assigned"
Assigned-To: "Defiant"
Created-By: "Enterprise"
Created: "2026-09-04T17:47:42Z"
Doc-Ref: "—"

Mehrere offene PRs fuer xlibre-Treiber (mouse, mach64, ati, qxl, nouveau, amdgpu, etc.) haben CI-Fehler bzgl. action-build-driver version. Alle betroffenen PRs analysieren, reparieren, durchbauen und sobald alle Lanes gruen sind mergen. Dazu gehoert auch das Rebase der asprintf/AC_USE_SYSTEM_EXTENSIONS-PRs auf den neuen action-build-driver-Stand. Board-Status aktuell halten, Report an McKinley/Enterprise.
