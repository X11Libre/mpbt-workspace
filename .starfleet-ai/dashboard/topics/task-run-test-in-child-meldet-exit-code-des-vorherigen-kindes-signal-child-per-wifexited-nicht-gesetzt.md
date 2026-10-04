Title: "run_test_in_child meldet exit-Code des VORHERIGEN Kindes - signal_child per WIFEXITED nicht gesetzt"
Category: active
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-10-04T06:29:40Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-run-test-in-child-meldet-exit-code-des-vorherigen-kindes-signal-child-per-wifexited-nicht-gesetzt

test/tests-common.c:19-31 (Auf master, Release-Zweigen identisch):

  while (*func) {
      cpid = fork();
      if (cpid) {
          waitpid(cpid, &csts, 0);
          if (!WIFEXITED(csts))
              goto child_failed;      // <-- springt ueber die Zuweisung
          exit_code = WEXITSTATUS(csts);
          if (exit_code != 0) {
      child_failed:
              printf(" FAIL\n");
              exit(exit_code);        // <-- exit_code ist noch der des VORHERIGEN Kindes
          }
      } else { ... }

Der Signal-Pfad (Kind von assert() mit SIGABRT beendet) ueberspringt exit_code = WEXITSTATUS(). Dadurch ist exit_code beim ersten Kind noch -1, ab dem zweiten Kind der Exit-Code des vorherigen, also in aller Regel 0.

Gemessene Folge: './tests; echo exit=0' liefert 0, obwohl ein Test FAIL meldet. Genau darum ist der signal_logging-Assert monatelang unentdeckt geblieben - CI zeigte 'unit OK' bei brennendem Assert. Und exakt darum ist derzeit PR #3833 rot, obwohl die Aenderung in ihm korrekt ist: der reparierte Assert laesst die Suite weiterlaufen und der naechste Defekt schlaegt zu.

Fix-Richtung: im Signal-Pfad exit_code selbst setzen (z.B. auf 128 + WTERMSIG(csts) oder einheitlich 1), nicht den des Vorgehaendels benutzen. Auf master zuerst, danach als Backport. Reihenfolge wichtig, sonst ist jeder erste Fix per CI unsichtbar.
