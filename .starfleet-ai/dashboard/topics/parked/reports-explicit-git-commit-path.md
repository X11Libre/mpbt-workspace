Title: "Reports (post-release): expliziter Git-commit/push-Pfad in internal/reports (analog dashboard topic commit)"
Category: parked
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-15T11:22:22Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/reports-explicit-git-commit-path

Parked (post-release). Aus dem Defiant-Befund m4514/m4520 zu internal/reports.

## Problem (gemessen)
Reportdateien liegen unter .starfleet-ai/var/reports/ und sind NICHT in der .gitignore-Ephemer-Liste (entfernt in Commit 9c2b9d49c1) -> sie sind git-getrackt. ABER: internal/reports hat KEINEN eigenen Git-Pfad (kein commit/push, anders als `dashboard topic commit`). Ein Report landet nur dann in Git, wenn ein Agent ihn per ws-commit mitnimmt. Kein Agent-Commit -> Report existiert nur auf Platte und ist bei einem var/-Wipe weg.

## Vorschlag
Expliziter Tool-Pfad: `reports submit` (und/oder delete) macht selbst `git add` + commit (+push), analog `dashboard topic commit`. Dann ist die Git-Persistenz nicht mehr von der Agent-Disziplin abhaengig. (Vorschlag von Defiant, nicht gemessen/implementiert.)

## Kontext
- doc/reports.md dokumentiert den Ist-Zustand (git-tracked, aber nur via Agent-ws-commit).
- Verwandt: parked/discussion-starfleetctl-redesigns (Abschnitt 3), parked starfleet/refactor-generic-rfc822-util.
- Refs: Defiant m4514/m4520/m4561.
