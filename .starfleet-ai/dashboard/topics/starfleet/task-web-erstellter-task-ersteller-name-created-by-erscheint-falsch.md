Title: "Web-erstellter Task: Ersteller-Name (created-by) erscheint falsch"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-04T16:21:08Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-web-erstellter-task-ersteller-name-created-by-erscheint-falsch

Task 'task-xlibre-drivers-finish-ci-bump-action-build-driver-to-v0-4-0-prs' wurde per Web-GUI erstellt, aber created-by wird als 'TestShip' angezeigt. TestShip ist offenbar eine Test-/Web-Identitaet, nicht der tatsaechliche Ersteller. Verdacht: Web-created-by nimmt eine falsche/zurueckgesetzte Ship-Identitaet (aehnlich bekannte McKinley/web.ship_id-Thematik). Diagnose+Fix noetig: korrekte Ship-Identitaet des Web-Erstellers ermitteln und nach Task-Frontmatter schreiben.
