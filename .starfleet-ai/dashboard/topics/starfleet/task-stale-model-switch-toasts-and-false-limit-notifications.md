Title: "stale model-switch toasts and false limit notifications"
Category: starfleet
Kind: "task"
Status: "in-progress"
Assigned-To: "Achilles"
Created-By: "Voyager"
Created: "2026-09-04T17:46:15Z"
Doc-Ref: "—"

Despite all ships having switched to Nemotron/NIM via model-proxy, stale toasts about model-switch and OpenCode Go limit reached keep appearing. Enterprise receives false notifications. The proxy should prevent client-side limit errors entirely. Investigate and fix the notification flow.

Analysis so far:
1. "Worker local total request limit reached" errors from NIM proxy are classified as "resource-exhausted" (auto-restart tag)
2. Auto-restart tags should NOT notify flagship (dispatchErrorHandle checks isAutoRestartTag)
3. Toast fields (ToastVariant, ToastTitle, ToastMessage) are in StatusRecord but NOT in BoardEntryJSON (web UI /api/board)
4. Web UI doesn't display toast notifications from ships
5. Plugin version 2.5.1 is deployed, but some ships might have older versions loaded

Next steps:
- Add toast fields to BoardEntryJSON
- Add toast display in web UI
- Verify flagship notification suppression for auto-restart tags
- Check if any ships have stale plugin versions
