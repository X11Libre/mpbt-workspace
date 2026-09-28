Title: "Backport PR 3750 (glamor memleak) auf Release-Linien"
Category: xlibre
Kind: task
Status: "open"
Created-By: "Voyager"
Created: "2026-09-28T13:02:07Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: xlibre/task-backport-pr-3750-glamor-memleak

Blockiert: PR 3750 ist OFFEN, nicht gemergt (erstellt 2026-09-28T12:59:49Z von Enrico Weigelt, mergeStateStatus UNSTABLE, CI laeuft noch). Ein Backport setzt einen gemergten Master-Commit voraus, den gibt es noch nicht. Zweiter Blocker: die Release-Zweige release/25.2, release/25.1, release/25.0 existieren im xserver-Remote NICHT mehr. Aus ls-remote --heads origin kommen nur master, master_backup_000 und diverse pr/*-Branches. Damit ist die Applicability-Pruefung des Backport-Skills nicht durchfuehrbar, und ich muss vor dem cherry-pick wissen, welche Zielfaecher es ueberhaupt gibt. Vorgeklaerte Erstmessung war ein Werkzeugfehler (starfleetctl github pr file-on-branch nimmt kein grep-Muster, Syntax <branch> <path>), nicht der Befund 'Funktion fehlt' - die Applicability ist offen, nicht geklaert. Nach dem Merge: Applicability je real existierendem Release-Zweig pruefen, dann github backport commit je Zweig, Dashboard-Backport-Tabelle an PR 3750, Cross-Links. Review von PR 3750 ist erledigt: passed, Label bot-review-passed, Kommentar mit Bot-Banner gepostet. Advisory nicht blockierend: unchecked calloc() in glamor/glamor_core.c:113 und unvalidiertes size aus glGetProgramiv in Zeile 112 - beides praeexistiert, nicht von diesem PR eingefuehrt. Kein ABI-Bruch, kein NVIDIA-Blob-Impact.
