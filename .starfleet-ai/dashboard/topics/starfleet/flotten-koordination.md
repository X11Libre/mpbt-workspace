Title: "automatische flottenkoordination bei abarbeitung von aufgaben"
Category: active
Status: "done"
Assigned-To: "Stargazer"
Created-By: ""
Created: ""
Doc-Ref: ""

Zielstellung: schiffe sollen sich automatisch gegenseitig benachrichtigen,
wenn sie eine aufgabe arbarbeiten, damit jeder bescheid weiß, was der andere
grade tut.

Insbesondere soll vermieden werden, daß unbeabsichtigt mehrere gleichzeitig
an der gleichen codebase arbeiten. manchmal kann es vorkommen, daß mehrere
am gleichen Problem arbeiten (zb. wenn ich parallel nochmal eine Analyse
beauftrage) - hier sollen sich die betreffenden schiffe abstimmen und ihre
erkenntnisse automatisch austauschen.

==> SOPs entsprechend nachschärfen.
--> die SOPs im starfleetctl selbst - anschließend starfleet neu bauen und ausrollen.
--> sauberes commit & push
Implemented 2026-08-03 (starfleetctl b1816ab, deployed via bootstrap + web/timer
restart, HTTP 200): SOPs sharpened —
- inter-ship-communication.md: new "Work coordination" section: announce
  codebase work (repo/branch/goal) before starting, check board/comms for who is
  already active, only one ship edits the same source at a time; parallel work
  on the same problem keeps separate branches/worktrees and exchanges findings
  via comms immediately (not only in the final report); publish discoveries on
  the bus while fresh.
- working-practices-for-ships.md: matching standing-instruction bullet.
Verified deployed: the new section is present in the installed
sop.d/starfleet-instructions/inter-ship-communication.md.
