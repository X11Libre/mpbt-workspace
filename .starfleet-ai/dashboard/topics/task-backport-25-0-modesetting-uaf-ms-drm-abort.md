Title: "Backport modesetting UAF (ms_drm_abort) to release/25.0"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "XL-0"
Created-By: "XL-0"
Created: "2026-10-08T11:17:28Z"
Doc-Ref: "—"

Source: master 2959d69753 (upstream xorg MR 2290), verified on fresh origin/master. Vulnerable on release/25.0 measured: hw/xfree86/drivers/modesetting/vblank.c:560 unguarded 'if (match(q->data, match_data))' (NOTE: path differs from master 25.1/25.2 - no video/ segment on 25.0). Prereq q->aborted field present on 25.0 (lines 504/510/605/646). 25.1 already fixed. Client-triggerable UAF, ASan repro upstream.

- 2026-10-08T11:25:31Z XL-0: PR #3867 erstellt (branch rfc/backport-25.0-modesetting-uaf). Quelle 2959d69753 auf frischem origin/master verifiziert (merge-base ok), 1 Commit ueber Basis, cherry-pick -x ohne -s, Pfad-Umbenennung via rename-Detection auf hw/xfree86/drivers/modesetting/vblank.c (video/-Reorg fehlt auf 25.0). Build -Dwerror=true: vblank.c.o + modesetting_drv.so ok, nur die 4 bekannten lokalen 25.0-Vorbestaende in unberuehrten TUs. Cross-Link auf Master-PR #3623 gepostet.

- 2026-10-08T11:25:46Z XL-0: completed
