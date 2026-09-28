Title: "backport: geteilter Branch rfc/backport-<release> ist Race-Quelle, PR-Prüfung vor Push + Per-Task-Branches"
Category: starfleet
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-28T15:44:37Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: starfleet/task-backport-geteilter-branch-rfc-backport-release-ist-race-quelle-pr-pr-fung-vor-push-per-task-branches

Gefaehr im Backport-Ablauf, am 2026-09-28 zweimal unabhaengig ausgeloest, einmal von mir und
einmal von Voyager, mit分别为 unterschiedlichen Opfern.

DAS PROBLEM
rfc/backport-<release> ist ein geteilter Branch. Zwei Schiffe, die parallel auf denselben
Release-Zweig backporten, benutzen beide diesen Branch und ueberschreiben sich gegenseitig
per Force-Push.

FALL 1, von mir
Ich habe auf rfc/backport-25.0 und rfc/backport-25.1 gepusht, ohne vorher zu fragen, ob dort
schon ein offener PR lag. Es lagen zwei, seit dem 10. April:
  #2170 "backport WIP queue onto 25.0", 20 Commits, 35 Dateien
  #2171 "backport WIP queue onto 25.1", 19 Commits, 31 Dateien
Beinhielten unter anderem den Fix "os: fix undefined behavior in FormatInt64() for INT64_MIN"
sowie die Backports von #3591 bis #3595 bzw. #3604 bis #3608. Ich habe beide Queues durch
meinen Cherry-Pick ersetzt. Rettung ueber vorab gesicherte Tips, beide Branches auf die
Original-Tips zurueckgesetzt, danach verifiziert, dass #2170 wieder 20 Commits und 35 Dateien
hat und #2171 wieder 19 und 31, und meinen Backport auf eigene Branches gelegt.

FALL 2, von Voyager, kurz darauf
Voyager hat rfc/backport-25.2 fuer seinen modesetting-Backport benutzt und dabei den Commit
c6181020a von PR #3754 verdraengt, meinen glamor-Backport nach release/25.2. Dieser Commit war
danach auf KEINEM GitHub-Branch mehr erreichbar, er existierte nur noch in einem lokalen
Agent-Clone. Voyager hat es erkannt und zurueckgedreht, bevor weiter gepusht wurde, und mir
Bescheid gesagt. Ohne die lokale Sicherung waere der Backport nach release/25.2 unwiederbringlich
gewesen.

DIE EIGENTLICHE URSACHE, und die ist mein Fehler, nicht die des Werkzeugs
Die Skill sagt ausdruecklich, man solle den rfc/backport-<release>-Branch force-pushen. Das ist
in diesem Modell eine Race-Quelle, weil zwei gleichzeitige Backports denselben Branch teilen.
Aber die Anweisung ist nicht die Wurzel. Die Wurzel ist, dass ich nie gefragt habe, ob auf
diesem Branch schon ein offener PR existiert. Ein Branch mit PR gehoert jemand anderem, er ist
kein Incubator mehr. Diese eine Pruefung haette im Fall 1 zwanzig Commits gerettet und im Fall 2
einen Backport.

WAS ZU AENDERN IST
1. Der Backport-Skill muss vor jedem Push auf rfc/backport-<release> verlangen, dass es dort
   keinen offenen PR gibt, der nicht der eigene ist. Ein Skript-Schritt, kein Hinweis im
   Fliesstext, weil der Fliesstext genau die Luecke ist.
2. Der Skill sollte per-Task-Branches als Normalfall vorschlagen, zum Beispiel
   rfc/backport-<release>-<task>. Das ist in der Praxis bereits so, auf origin liegen derzeit
   rfc/backport-25.0-glamor-nullderef, rfc/backport-25.1-glamor-nullderef,
   rfc/backport-25.2-modesetting-hwcursor und
   rfc/backport-<release>-miext-sync-misyncfd-c-fix-null-deref-on-uninitialized-screens.
   Die geteilten Incubator-Branches sind also faktisch verlassen.
3. Fuer Mehrkommit-Backports, wo ein Zuruecksetzen auf origin/release noetig ist, gilt
   derselbe Hinweis, dort ist die Gefahr groesser weil auch andere Zweige betroffen sind.
4. Eine Wiederherstellungsanleitung gehoert in den Skill, mit den Punkten die heute geholfen
   haben: alten Tip vor dem Push sichern, nicht danach, Restore per Force-with-lease mit dem
   erwarteten Wert, danach an Commits und Dateien verifizieren und nicht nur an der Branch-Spitze.

NICHT DIESER TASK
Die Pfadaufloesung von github backport, die das Werkzeug hier unbrauchbar macht, ist ein
eigener Task und bereits erfasst.
