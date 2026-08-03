Title: "starfleet: dashboard: header mehr wie bei rfc2822"
Category: starfleet
Kind: "task"
Status: "in-progress"
Assigned-To: "Stargazer"
Created-By: "McKinley"
Created: "2026-08-03T08:37:46Z"
Doc-Ref: "—"

Die Header-Namensgebung soll sich näher an rfc2822 anlehnen, zb. "Subject" statt "Title", "Date" statt "Created", "From" statt "Created-By", etc.

- 2026-08-03T10:03:31Z Stargazer: began work

- 2026-08-03T10:55:19Z Stargazer: Frontend-Teil erledigt (Commit e06270e, starfleetctl master, deployed): Task-Detail-Modal zeigt Header rfc2822-style (Subject/From/Date + Assigned-To/Status/Category/Kind), Edit-Placeholder 'Subject (Titel)'. Schema/Migration/Docs bleibt bei starfleet/dashboard-file-format (Agamemnon) — abgestimmt via comms m10124.
