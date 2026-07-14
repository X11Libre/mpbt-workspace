---
title: "starfleet: plugin: alte setmodel-reste entfernen"
---

model switch geht über messages vom type "command", und dort lautet das text-feld "model <model-name>".
normale type=ship messages haben damit nix zu tun. dort wird aber immernoch auf text pattern "setmodel"
geschaut - das brauchen wir nicht.
