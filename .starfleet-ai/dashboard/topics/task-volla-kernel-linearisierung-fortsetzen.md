Title: "volla kernel linearisierung fortsetzen"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Barcley"
Created-By: "McKinley"
Created: "2026-08-10T18:08:22Z"
Doc-Ref: "—"

1. Jetzt nochmal schrittweise Linearisierung: ich hab das schon angefangen. mein letzter Stand ist branch wip/linearize-volla-15.0-step8. zweige von dort ab (nummerierung *step9 ... usw ...) und löse Schritt um Schritt die jeweils oberste Merge-Node auf. Nachdem eine merge-node aufgelöst ist, mit dem volla-tree vergleichen - es sollte keine Differenz mehr da sein (im worst case ein extra commit anhängen, das den tree wieder ans original angleicht). danach nächste branch abzweigen und wieder die nächste merge-node linearisieren - die schleife bis alles oberhalb des letzten (im original enthaltenen) upstream bzw LTS tag linear ist. nicht den tree-abgleich vergessen.

nach jedem schritt report einstellen und bericht an mckinley.

2. schrittweises rebase auf aktuelle mainline releases: für jede release-base neue branch abzweigen und dann rebase. konflikte auflösen. caret-vergleich, ob die differenz zwischen voriger und aktueller mainline-base gleich der differenz zwischen vor und nach dem rebase ist. 
so stück für stück von einem release zum nächsten hoch arbeiten. (evtl. auch kleinere schritte, zb. von einem größeren merge zum nächsten).
zwischendurch (zb. bei jedem mainline-release) report erstellen und bericht an mckinley
