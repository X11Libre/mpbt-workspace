Title: "#3723 (Xephyr pScreen->myNum) regressive NULL-Deref - Fix noetig"
Category: parked
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-25T20:43:20Z"
Assigned-To: "metux"
Doc-Ref: "—"
Slug: parked/task-3723-xephyr-pscreen-mynum-regressive-null-deref-fix-noetig

Root cause: ephyrMapFramebuffer (ephyr.c:226) und processScreenOrOutputArg (ephyrinit.c:150) dereferenzieren screen->pScreen->myNum, aber pScreen ist beim scrinit-Zeitpunkt noch NULL (wird erst in KdScreenInit kdrive.c:866 gesetzt) -> Segfault 0x0 beim Startup, alle ephyr-CI-Tests failen. Fix: dort weiterhin screen->mynum verwenden. Report r-1790368926345851498, PR-Kommentar gepostet.
