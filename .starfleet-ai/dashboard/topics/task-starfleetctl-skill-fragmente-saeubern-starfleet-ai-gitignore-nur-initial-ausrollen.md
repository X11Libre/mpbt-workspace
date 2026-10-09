Title: "starfleetctl: Skill-Fragmente saeubern + .starfleet-ai/.gitignore nur initial ausrollen"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "LaForge"
Created-By: "Enterprise"
Created: "2026-10-09T10:13:09Z"
Doc-Ref: "—"

Zwei Nacharbeiten aus der Skill-Rettung durch LaForge (Bootstrap hat Fehler eingespielt):

1. MURKS IN DEN SKILL-FRAGMENTEN: fragments/starfleet-skills/starfleetctl-dev/SKILL.md und .../starfleet-sessions/SKILL.md enthalten Artefakte aus dem Recovery-Bundle bzw. Debug-Reste:
   - starfleetctl-dev Z.315/316: 'test' / 'test append' (Debug-Reste)
   - starfleetctl-dev Z.318: '### ABSCHNITT 5 (starfleetctl-dev) — aus ee3a6b7271'
   - starfleetctl-dev Z.370: '### ABSCHNITT 6 (starfleetctl-dev) — aus d2e1a5d92d'
   - starfleet-sessions Z.100: '### starfleet-sessions-Regel — aus 36380eff06'
   Diese Marker-Zeilen gehoeren NICHT in den Skill — nur der eigentliche Inhalt. Entfernen.

2. .gitignore NUR INITIAL AUSROLLEN: fixStarfleetAIGitignore() (internal/bootstrap/checks.go:~1220) schreibt .starfleet-ai/.gitignore UNBEDINGT aus dem Template (string == starfleetAIGitignoreContent) und ueberschreibt damit lokale Anpassungen. Soll nur initial (wenn Datei fehlt) geschrieben werden; eine vorhandene Datei nicht mehr anfassen. verifyStarfleetAIGitignore entsprechend lockern (nur Existenz pruefen, nicht Byte-Gleichheit).
   Hintergrund: ein lokaler Fix (reports sollen mitversioniert werden -> /var/reports/ ausgenommen) wurde so zunichte gemacht.

Nach den Fixes: make all, commit+push, ./starfleet-bootstrap -> Workspace-Skills regeneriert sauber, .gitignore bleibt unangetastet.
