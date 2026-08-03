Title: "bug: web: schiffschat - fehlende / falsche filte"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Stargazer"
Created-By: "Leto"
Created: "2026-08-01T14:05:12Z"
Doc-Ref: "—"

Im direkten chat mit schiff (schiff aus liste wählen und dann auf chat clicken): da erscheinen massenhaft messages von/ganz anderen schiffen die nix mit dem grad geöffneten zu tun haben.
Es sollte nur der chat mit diesem schiff erscheinen
Fixed 2026-08-03 (starfleetctl ae7f027): the per-ship chat used
ConversationWithViewer, which leaked every message involving the web viewer
(McKinley) into any ship's conversation — e.g. all McKinley→Stargazer
messages showed up when chatting with Enterprise. Switched to Conversation()
(FROM==ship || TARGET==ship || TARGET=="all") and dropped the redundant
viewer clause. Regression tests in internal/comms/json_test.go. Deployed via
bootstrap + web/timer restart; verified live: 0 leaked messages, newest-first.
