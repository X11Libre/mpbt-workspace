---
title: "agent instructions schärfen: dashboard list command"
status: "done"
---

Agents versuchen immernoch beim Startup das dashboard falsch aufzurufen.

beispiel auf enterprise (direkt im lokalen terminal gestartet):

`.starfleet-ai/bin/starfleetctl dashboard list`

Instructions / SOPs dahingehend schärfen, daß die agents sofort wissen,
wie das korrekte kommando lautet und nicht erst raten / probieren müssen.
(verbrennt nur unnötig tokens)

## Erledigt

- starfleet-Skill (`fragments/starfleet-skills/starfleet/SKILL.md`)
  angepasst: `dashboard list` ist kein Subcommand; Topics immer via
  `dashboard topic list --json` auflisten. Quell-Änderung committet
  (starfleetctl @ 6400d6d), via `make` geprüft, gepusht und per
  `./starfleet-bootstrap` ausgerollt.
