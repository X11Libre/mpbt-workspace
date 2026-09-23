Title: "xserver PR #3725: CreateConnectionBlock heap-overflow fix (bounded DIX_FOR_EACH_SCREEN)"
Category: active
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-23T19:36:25Z"
Assigned-To: "Defiant"
Doc-Ref: "—"
Slug: task-xserver-pr-3725-createconnectionblock-heap-overflow-fix-bounded-dix-for-each-screen

PR #3725 (dix: pass number of screens to CreateConnectionBlock) hat Heap-Buffer-Overflow im Xinerama-Mehrscreen-Pfad: Root-Befuellung laeuft ueber DIX_FOR_EACH_SCREEN (screenInfo.numScreens), Block fuer numRoots=1 alloziiert. Fix (Praetor/Praez.): DIX_FOR_EACH_SCREEN-Variante mit Limit in dix/screenint_priv.h + in CreateConnectionBlock mit setup.numRoots verwenden. Defiant, separater worktree, commit amend + force-push auf pr/master-dix-pass-number-of-screens-to-createconnectionblock-_2026-09-23_19-23-20. Lokal xnest/xephyr/xvfb + idealerweise echter Mehrscreen-PanoramiX-DDX. Danach Enterprise Re-Review + starfleet report.
