Title: "Xlibre Prototyp Xaverius-Implementation"
Category: xlibre
Kind: "task"
Status: "parked"
Assigned-To: "—"
Created-By: "McKinley"
Created: "2026-10-30T17:50:50Z"
Doc-Ref: "—"

* Verwende die Spec in /home/nekrad/src/xorg/mpbt-workspace/_WORK_/xav/xav-design
* in sauberen, leicht verständlichen Schritten, commit für commit
* separate branch rfc/xaverius --> separater worktree
* stets auch auf saubere, verständliche commit messages achten
* zwischendurch starfleet-reports mit aktuellem Zwischenbericht einstellen (darf auch der gleiche report updated werden)
* möglichst komplett autonom machen
* andere schiffe dürfen gern zur Hilfe genommen werden -> lastverteilung
* zwischendurch auch immer wieder die spec repo nochmal pullen und dann nochmal anschauen, weil parallel evtl. noch Änderungen rein kommen können (die aktuelle branch docs/restructure-2026-10-21 dort ausgecheckt lassen)

Teil A:

Phase 1:
* skelett der Extension
* zunächst nur reines Protocol-Handling 
* alle Calls implementieren, aber nur als Dummies, die sich genauso verhalten als gäbe es grad keine nutzbaren GPUs (keine physical devices)
* noch keine DDX-Seite in dieser Phase
* sorgfältig gegen die Spec abprüfen
* einen meson-switch für conditional compile  -> per default aus, aber in der CI explizit aktivieren

Phase 2:
* screen call vectors für DDX'e - werden als devPrivate's registriert (pointer auf record mit state und call vectors)
* ggf. auch weitere devPrivate's  in anderen resources (zb. Window, etc) falls nötig
* caller-Seite (request handlers) prüfen vor dem Call zunächst ob der betreffende screen das zugehörige devPrivate installiert hat - wenn NULL, dann so verhalten als unterstützt der screen keine nutzbaren GPUs
* ggf. erforderliche entrypoints für DDX'e (zb. registrierung, usw)
* ab diesem Punkt muß es möglich sein, daß DDX'e ihre Implementation eindocken können (zb. eine register function, mit der sich das DDX in einen screen eindockt)
* tatsächliche Unterstützung (die später kommt) soll für jeden Screen separat eindockbar sein 
(dh. es ist erlaubt, daß in einem multi-screen setup manche screens es supporten und andere nicht)

Phase 3:
* DDX implementation für xfree86 -> modesetting treiber
* im screen setup dockt sich das DDX / der xf86-treiber in die extension ein (über in register-function aus phase 2)
* beim shutdown (close screen) wieder sauber entfernen
* außerdem das gleiche für Xmodesetting (kdrive-based)

Teil B:

* Test-Client / Demo
* ähnlich glxgears nachempfunden
* demonstriert einfaches rendering und anzeige in einem X11 window
* Programmiersprache beliebig, darf auch gern komplett in python oder auf Basis von go-x11proto gebaut werden.
* wichtig ist nur, daß sich das Demo Ausführen läßt uns die Grundfunktionen demonstriert
* optional das Demo auch in den CI-Test mit einbinden (wenn es sinnvoll machbar ist)
