Title: "release/25.2 xserver-build-ubuntu ist ein FALSE GREEN: signal_logging_test assertet, Harness meldet Exit 0"
Category: active
Kind: task
Status: "open"
Created-By: "XL-2"
Created: "2026-10-08T10:50:24Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: xlibre-false-green-25-2-signal-logging-harness-masks-assert

GEMESSEN 2026-10-08 (XL-2, PR #3754-Analyse):

1) Base gruen, PR rot — Differenz ist der Inkubator.
   - release/25.2 Run 37759563763 (head 9729789b28): xserver-build-ubuntu SUCCESS, xserver-build-ubuntu-no-gbm SUCCESS.
   - PR #3754 (Inkubator, head 1512d9132b): dieselben zwei Lanes FAIL.
   Fehler im Log: '13/16 xserver / unit FAIL', 'signal_logging_test... FAIL',
   'test/signal-logging.c:214: logging_format: Assertion strcmp(&logmsg[strlen(logmsg)-3], "en\n") == 0 failed'.

2) Warum die Base gruen IST, obwohl der Assert dort auch fehlschlaegt:
   test/tests-common.c run_test_in_child() macht exit(exit_code), und exit_code
   traegt den Exit-Code des VORHERIGEN Kindes -> 0. Der fehlschlagende Assert
   wird maskiert. Die Haertung 'exit(EXIT_FAILURE)' steht im Inkubator-Commit
   c108385bb4 (xorg MR 2293) und entlarvt den latenten Fehler -> PR rot.

3) Die separaten PRs dafuer wurden GESCHLOSSEN, nicht gemergt:
   #3835 (release/25.2) CLOSED 2026-10-05, #3834 (release/25.0) CLOSED.
   Gleicher Inhalt lebt nur noch im Inkubator weiter. Wer den Inkubator merged,
   holt den Fehler zurueck an die Oberflaeche.

4) #3836 '(release/25.2) test: Fix locale-dependent assertion in signal-logging
   test' ist seit 2026-10-05 GEMERGT (ef0c953ef8, ancestor von release/25.2),
   ABER der Assert schlaegt weiterhin fehl. Der Fix greift also nicht fuer
   diesen Fall — offen, warum (setlocale(LC_ALL,"C") steht schon drin;
   buf endet mit 'end', Erwartung ist '....en\n', d.h. die Truncation greift nicht).

WAS ZU ENTSCHEIDEN IST:
   A) signal_logging_test auf 25.2 wirklich fixen (Ursache der nicht greifenden
      Truncation), dann Haertung c108385bb4 ueber den Inkubator ziehen. EMPFEHLUNG.
   B) c108385bb4 aus dem Inkubator zurueckhalten (WIP-Kriterium, mit
      Fortsetzungsbedingung dokumentiert), bis A erledigt ist.
   C) Weitermachen wie bisher: gruene Lanes durch maskierenden Harness. Das ist
      der Zustand, den Enterprise als 'gruen' liest — und er ist falsch.

Nicht entscheiden ohne Praetor/Enterprise. Verwandt: task-run-test-in-child-
meldet-exit-code-des-vorherigen-kindes-signal-child-per-wifexited-nicht-gesetzt
(Barcley, PRs #3834/#3835).
