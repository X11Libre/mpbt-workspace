Title: "dix/connsetup: connBlockScreenStart-Globale durch Helper aus dem Connection-Info-Block ersetzen"
Category: xlibre
Kind: "task"
Status: "done"
Assigned-To: "Interpid"
Created-By: "Enterprise"
Created: "2026-09-26T11:46:02Z"
Doc-Ref: "—"

Ziel: Die globale Variable connBlockScreenStart (dix/dix_priv.h:71, dix/connsetup.c:26) entfaellt vollstaendig. Sie dupliziert Zustand, der bereits vollstaendig aus dem Connection-Info-Block selbst ableitbar ist, und sie ist int, obwohl der Offset ein size_t ist.

1. Helper in dix/connsetup.c einfuehren, z.B. size_t dixConnBlockScreenStart(const char *connInfo): berechnet den Offset des Screen-Bereichs (erstes xWindowRoot) durch Walken des Block-Headers: xConnSetup (nbytesVendor, numFormats, numRoots) -> Vendor-String + 4-Byte-Pad -> numFormats mal xPixmapFormat -> Screens beginnen. Rueckgabe size_t.

2. Alle bisherigen Verwendungen ersetzen:
   - dix/connsetup.c:226 in dixNewConnectionInfoBlock(): Helper auf newone anwenden
   - dix/connsetup.c:244 (*scrOffset): Wert aus dem Helper statt aus der Globalen
   - Xext/panoramiX/panoramiXprocs.c:595: ConnectionInfo + connBlockScreenStart -> ConnectionInfo + Helper(ConnectionInfo)
   - Xext/panoramiX/panoramiX.c:656: die Zuweisung entfaellt komplett, der Block traegt die Info bereits
   - dix/dix_priv.h:71: extern entfernen, stattdessen den Helper dort (bzw. im passenden priv-Header) exportieren

3. dixBuildConnectionBlock() und der out-param screenDataOffset: pruefen, ob nach der Aenderung noch jemand sie nutzt. panoramiX.c nutzt screenDataOffset fuer seinen eigenen lokalen Wert - das ist ok und bleibt.

4. Verbindlichkeit: der Connection-Info-Block muss byte-identisch auf der Leitung bleiben. Der Helper MUSS exakt denselben Offset liefern, den der Builder berechnet hat. Solange der Builder den out-param noch berechnet, eine Debug-/Build-Assertion danebenstellen, die beide Werte vergleicht.

5. dixNewConnectionInfoBlock() muss weiterhin alle Roots patchen, mit numRoots aus dem Block (nicht aus screenInfo). Der bestehende Kommentar "attention: this still depends on setup block screens matching screenInfo.screens" gilt unveraendert.

6. Keine neue mutable Globale. Kein ABI-Bruch, keine Verhaltensaenderung fuer Extensions. Es werden keine neuen Dateien erwartet.

Arbeitsort: Worktree _WORK_/worktrees/xserver/screenlist, Branch wip/screenlist (steht auf master-Tip 322305bfe6, kein Rebase noetig). NICHT im primaeren mpbt-Clone _WORK_/xserver-master/sources/xlibre/xserver arbeiten - der ist passiv, andere Schiffe lesen und bauen dort. Kein eigenes Worktree anlegen, das hier ist reserviert.

Verifikation: bauen, dann testen mit Xvfb, Xnest und Xephyr ueber simple-xinit (siehe xserver-testing Skill). PanoramiX-Fall mit testen, da panoramiX.c und panoramiXprocs.c betroffen sind - ein reiner Single-Screen-Test reicht nicht.

Sind Xephyr (Screen-Nesting) und PanoramiX nicht in derselben Konfiguration testbar, beide Varianten separat fahren und das im Report festhalten.

Abschluss: starfleetctl reports submit mit --task-ref auf diesen Task, plus comms an Enterprise und McKinley. Branch auf GitHub pushen, Pipeline beobachten.

- 2026-09-26T13:19:10Z Enterprise: CI-Run 36241690977 auf wip/screenlist abgeschlossen: conclusion=success, 26 Jobs gruen, 5 skipped (abi_changed=false, deps-images cached, Signed-Off-By nur bei PRs), 0 Fehler. commit 9fe8290e63.

- 2026-09-26T13:19:18Z Enterprise: completed
