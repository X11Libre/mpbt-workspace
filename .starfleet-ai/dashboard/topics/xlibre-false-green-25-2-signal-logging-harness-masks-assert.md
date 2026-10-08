Title: "release/25.2 xserver-build-ubuntu ist ein FALSE GREEN: signal_logging_test assertet, Harness meldet Exit 0"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "XL-2"
Created: "2026-10-08T10:50:24Z"
Doc-Ref: "—"

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

- 2026-10-08T10:58:35Z XL-2: Wurzelursache analysiert (XL-2, read-only, kein Build): Der Assert bei test/signal-logging.c:214 ist mit dem aktuellen os/log.c ARITHMETISCH UNERFUELLBAR — und damit ein TESTFEHLER, kein Produktivfehler. Rechnung (alle Groessen aus dem Code gemessen): LOG_MSG_BUF_SIZE=1024 (os/log.c:746); prepMsgHdr liefert Prefix '(EE) ' = 5 Bytes (X_ERROR_STRING '(EE)'+Space, os/log.c:148/756-767); vpnprintf laeuft unter 's_idx < size-1' mit size=1024-5=1019 -> max 1018 Zeichen, return s_idx (os/log.c:469/633); len=5+1018=1023; writeLog erzwingt 'if (1024-len==1) buf[len-1]=\n' -> buf[1022]='\n' (os/log.c:766). Folge: sichtbare Message = '(EE) ' + 1017 Punkte + '\n'. format selbst hat 'e','n','d' erst bei Index 1020-1022 (memset+strcpy, test/signal-logging.c:184-185), die liegen bei Buffer-Index 1025+ und werden nie erreicht. Letzte 3 Zeichen sind damit '..\n', nicht 'en\n'. Fuer 'en\n' muesste vpnprintf 1023 Zeichen schreiben, d.h. size>=1024, d.h. Prefix-Laenge 0. Der Test erwartet also ein truncation-Verhalten OHNE Message-Praefix. Gegenprobe: die vorige Assertion 'strcmp(logmsg, "(EE) test message")==0' PASST — der Praefix ist also wirklich '(EE) ' und nicht leer. Zusatz: test/tests-common.c ist zwischen 25.1, 25.2 und master BINAER IDENTISCH (alle drei 'exit(exit_code)'), d.h. AUCH 25.1 maskiert denselben Fehler — 25.1s gruene Lane ist damit kein Gegenbeleg. Inkubator beruehrt os/log.c, os/fmt.c und test/signal-logging.c NICHT (gemessen: Dateiliste des Inkubators), einziger Eingriff ist test/tests-common.c. Konsequenz: vor dem Haertungs-Commit c108385bb4 muss die TESTERWARTUNG angepasst werden (oder die Truncation bewusst geaendert — Praetor-Entscheidung, Produktivverhalten vs. Test).
