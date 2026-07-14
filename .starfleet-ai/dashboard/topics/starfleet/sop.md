---
title: "terminology SOP (standard operating procedure)"
---

Für die agent-instructions (zb. die aus fragmenten compilierten AGENTS.md oder CLAUDE.md,
oder auch die skills) soll zukünftig die Terminologie SOP (standard operating procedure)
verwendet werden. Also soll auch das entsprechende starfleetctl-command, das diese
compiliert / installiert auch dementsprechend 'sop' statt 'agents' heißen.

* command renaming in 'sop'
* path name(s) des/der projekt-lokalen fragment-verzeichnis(e) via config yaml anpaßbar machen (zb. project.yaml)
* help-texte entsprechend anpassen
* skills / starfleet-sop's entsprechend anpassen
* sämltiche dokumentation entsprechend anpassen
* die existierendende `agents.d` directory im workspace bleibt vorerst als legacy supported
  (evtl. nennen wir das später komplett um), aber die starfleetctl-internen fragmente schon umbenennen
