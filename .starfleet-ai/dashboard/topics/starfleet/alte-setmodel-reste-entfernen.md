Title: "starfleet: plugin: alte setmodel-reste entfernen"
Category: active
Status: "assigned"
Assigned-To: "Enterprise"
Created-By: ""
Created: ""
Doc-Ref: ""

model switch geht über messages vom type "command", und dort lautet das text-feld "model <model-name>".
normale type=ship messages haben damit nix zu tun. dort wird aber immernoch auf text pattern "setmodel"
geschaut - das brauchen wir nicht.
