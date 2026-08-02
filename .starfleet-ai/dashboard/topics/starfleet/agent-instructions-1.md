Title: "agent instructions schärfen: dashboard list command"
Category: active
Status: "done"
Assigned-To: "Stargazer"
Created-By: ""
Created: ""
Doc-Ref: ""

Agents versuchen immernoch beim Startup das dashboard falsch aufzurufen.

beispiel auf enterprise (direkt im lokalen terminal gestartet):

`.starfleet-ai/bin/starfleetctl dashboard list`

Instructions / SOPs dahingehend schärfen, daß die agents sofort wissen,
wie das korrekte kommando lautet und nicht erst raten / probieren müssen.
(verbrennt nur unnötig tokens)

Update (2026-07-31): passiert leider immernoch - auch nach neustart.
