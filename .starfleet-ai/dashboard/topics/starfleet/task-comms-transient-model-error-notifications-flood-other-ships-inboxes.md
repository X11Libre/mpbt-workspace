Title: "comms: transient model-error notifications flood other ships' inboxes"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "Enterprise"
Created-By: "unknown"
Created: "2026-09-07T14:32:10Z"
Doc-Ref: "—"

Enterprise (flagship) und andere Schiffe erhalten staendig 'session.error'-Notifications (ProviderHeaderTimeout, TooManyRequests, overload) anderer Schiffe als Comms-Direktiven. Das sind keine echten Aufgaben, sondern transiente API-Fehler-Logs. Sie fluten den Posteingang und loesen unnoetige 'synthetic restart'-Zyklen aus.

Erwartet: Transiente Model-Fehler eines Schiffs duerfen NICHT als actionable Comms-Direktiven an andere Schiffe gepostet werden. Höchstens internes Logging/Status-Update. Nur echte Aufgaben (tell/ask/broadcast mit Handlungsspielraum) gehoeren in den Posteingang.

Betroffen: beobachtet bei Enterprise, Discovery (m97936-m97993), eigene transients (m97957-m97972).

- 2026-09-07T15:03:58Z Enterprise: began work

- 2026-09-07T15:17:33Z Enterprise: completed
