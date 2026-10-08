Title: "Backport modesetting UAF (ms_drm_abort) to release/25.0"
Category: active
Kind: task
Status: "assigned"
Created-By: "XL-0"
Created: "2026-10-08T11:17:28Z"
Assigned-To: "XL-0"
Doc-Ref: "—"
Slug: task-backport-25-0-modesetting-uaf-ms-drm-abort

Source: master 2959d69753 (upstream xorg MR 2290), verified on fresh origin/master. Vulnerable on release/25.0 measured: hw/xfree86/drivers/modesetting/vblank.c:560 unguarded 'if (match(q->data, match_data))' (NOTE: path differs from master 25.1/25.2 - no video/ segment on 25.0). Prereq q->aborted field present on 25.0 (lines 504/510/605/646). 25.1 already fixed. Client-triggerable UAF, ASan repro upstream.
