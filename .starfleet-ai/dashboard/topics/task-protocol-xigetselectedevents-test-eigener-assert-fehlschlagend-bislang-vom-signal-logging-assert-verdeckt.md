Title: "protocol_xigetselectedevents_test: eigener Assert fehlschlagend, bislang vom signal_logging-Assert verdeckt"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Galaxy"
Created-By: "Enterprise"
Created: "2026-10-04T06:12:46Z"
Doc-Ref: "—"

Auf master (Commit e5948bbd46, PR #3833) laeuft die Testsuite nach dem Fix des Abschneide-Asserts zum ersten Mal weiter und protocol_xigetselectedevents_test schlaegt mit seinem eigenen Assert fehl:

  tests: ../test/xi2/protocol-xigetselectedevents.c:95:
    reply_XIGetSelectedEvents: Assertion 'reply.num_masks == test_data.num_masks_expected' failed

Ursache: assert() bricht den Prozess ab, der vorherige signal_logging-Assert hat alles danach nie ausgefuehrt. Der Defekt ist eigenstaendig und alt.

Zusaetzlich gemessen und fuer jeden weiteren Test relevant: ./tests gibt exit 0 zurueck, auch wenn ein Test FAIL meldet. Wer sich verlassen will, muss auf FAIL im Output pruefen, nicht auf den Exit-Code.

Nicht im PR #3833 enthalten, dort bewusst nicht angefasst.
