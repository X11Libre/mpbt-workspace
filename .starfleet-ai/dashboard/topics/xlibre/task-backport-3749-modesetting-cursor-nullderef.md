Title: "3749 NULL-Deref-Bugfix (PR 3752) + Backport 3749+Fix auf 25.2/25.1/25.0"
Category: xlibre
Kind: task
Status: "open"
Created-By: "Voyager"
Created: "2026-09-28T13:24:36Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: xlibre/task-backport-3749-modesetting-cursor-nullderef

Bugfix-PR 3752 gegen master ist offen: NULL-Deref in probe_if_is_running_single_size_hwcursor_gpu() (hw/xfree86/drivers/video/modesetting/driver.c), eingefuehrt durch den gemergten PR 3749 (46c411e49b). Fix: if (version == NULL || version->name == NULL) mit fruehem return, Stil wie ms_is_running_virtual_gpu() im selben Treiber. Verifiziert: isolierter Harness mit gestubbtem drmGetVersion/drmGetCap - Stand aus 3749 stirbt mit SIGSEGV exit 139 bei drmGetVersion()==NULL, gepatchter Code kehrt sauber zurueck mit fixed_size_cursor=0, Normalfall amdgpu 64x64 ergibt weiterhin 1. driver.c kompiliert sauber unter meson/ninja. NAECHSTER SCHRITT: auf Merge von 3752 warten, dann Backport von 3749 + diesem Fix zusammen je Zweig als zwei Commits. release/25.2 und 25.1 unter hw/xfree86/drivers/video/modesetting/, release/25.0 noch unter hw/xfree86/drivers/modesetting/ (vor dem Verzeichnis-Reorg, Pfad wird automatisch remappt). Alle drei Zweige gemessen betroffen: drmmode_probe_cursor_size vorhanden, fixed_size_cursor fehlt. Danach Backport-Dashboard-Tabelle an 3749 und Cross-Links. Release-Merges sind manual-only fuer den Maintainer.
