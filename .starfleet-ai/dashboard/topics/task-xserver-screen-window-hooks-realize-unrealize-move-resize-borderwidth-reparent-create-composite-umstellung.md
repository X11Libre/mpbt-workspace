Title: "xserver: screen window hooks (Realize/Unrealize/Move/Resize/BorderWidth/Reparent/Create) + composite-Umstellung"
Category: active
Kind: task
Status: "open"
Created-By: "Defiant"
Created: "2026-10-13T14:18:42Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-xserver-screen-window-hooks-realize-unrealize-move-resize-borderwidth-reparent-create-composite-umstellung

Praetor-Auftrag: dix screen_hooks um Window-Operationen erweitern und composite (compCreateWindow/compRealizeWindow/compUnrealizeWindow/compMoveWindow/compResizeWindow/compChangeBorderWidth/compReparentWindow) von ScreenProc-Wrap auf Hooks umstellen. Step-by-step Einzelcommits (erst Hooks, dann composite je Operation), einzeln pruef-/submittbar als PRs.
