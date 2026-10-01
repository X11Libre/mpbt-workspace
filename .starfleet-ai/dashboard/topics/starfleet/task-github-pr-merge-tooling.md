Title: "starfleetctl: github pr merge + release/*-Schutz + PR-Check-Auswertung ergaenzen"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-10-01T10:05:16Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: starfleet/task-github-pr-merge-tooling

Aus einer echten Review-Session am 2026-09-30 (PR #3769). Drei Luecken, alle gemessen, keine geraten.

LÜCKE 1 — es gibt kein Merge-Kommando.
Die Verben unter 'starfleetctl github pr' sind: view, ci, job-logs, comment, label,
request-reviewers, set-body, append-body, amend-push, checkout, claim, show-branch-file,
show-conflict, file-on-branch, wait-green, mk-agent-clone, make. Kein 'merge'.
Mergen geht nur ueber 'gh pr merge'. Folge: die Merge-Policy des Projekts haengt an der
Disziplin jedes einzelnen Aufrufs und ist nicht durchsetzbar.

LÜCKE 2 — es gibt keinen release/*-Schutz.
Auf X11Libre/xserver ist allow_squash_merge=false und allow_merge_commit=false, nur
rebase ist erlaubt. Das ist Policy, keine Einschraenkung. Release-Branches (release/25.2,
25.1, 25.0) duerfen laut SOP NIE automatisch gemergt werden — dafuer gibt es heute keinen
Mechanismus, nur eine Regel im Skill-Text, die ein Automat nicht kennen kann.

LÜCKE 3 — Merges koennen ungeprueft durchrutschen.
Wenn PR #3769 mit 'bot-review-passed' und gruener CI gemerged wird, ist der gelabelte
Befund nicht automatisch verifiziert. Nach dem Merge muss geprueft werden, dass der Inhalt
tatsaechlich der geprueft-reviewte Stand ist. Konkret bei #3769: der Merge-Commit muss
byteweise dem PR-Head entsprechen, der dem Review zugrunde lag.

SOLL (Reihenfolge):
1. 'starfleetctl github pr merge <pr#>' ergaenzen. Merge-Mode fest auf --rebase verdrahtet;
   --squash und --merge-commit werden gar nicht erst angeboten (kein Flag). Damit ist
   'nur rebase' strukturell statt disziplinarisch gesichert.
2. Vor dem Merge HART abbrechen, wenn baseRefName auf release/* zeigt — mit klarer
   Begruendung in der Ausgabe, nicht nur stillem Abbruch. Manuell, durch den Maintainer.
3. Vor dem Merge pruefen:
   - CI vollstaendig durch und kein Failure (statt nur 'kein pending')
   - Mergestate, labels, base-branch-Zustand (rebase/merge/squash erlaubt)
4. Nach dem Merge den Inhalt verifizieren: Merge-Commit gegen den im Review geprueften
   PR-Head diffen und die Abweichung melden. Bei Abweichung: laut, nicht still.
5. --delete-branch nur auf ausdrueckliches --delete-branch; nicht voreingestellt.
   (Der Maintainer hat nicht bestaetigt, ob der Branch nach Merge weg soll.)

REFERENZ, wie sich ein vergangener Merge wirklich identifizieren laesst — Rebase und
Squash ergeben BEIDE genau einen Parent, die Parent-Anzahl unterscheidet sie nicht:
  Rebase:  1 Parent, Autor + Autor-Datum ERHALTEN, Committer-Datum neu
  Squash:  1 Parent, Autor/Datum auf den Merger umgeschrieben
  Merge:   2 Parent, Autor + Autor-Datum erhalten
Bei PR #3769 wurde das zuerst falsch als Squash beurteilt, genau wegen der Parent-Anzahl.
Diese Unterscheidung gehoert ins Tooling oder mindestens in die Ausgabe nach dem Merge.

GRUNDLAGEN, live geprueft (nicht aus dem Gedaechtnis):
  gh api repos/X11Libre/xserver -> allow_rebase_merge=true, allow_squash_merge=false,
  allow_merge_commit=false, allow_auto_merge=false
  gh version 2.46.0
Beim Implementieren: make all muss gruen sein (AGENTS.md verlangt das), Commit mit
Signed-off-by.
