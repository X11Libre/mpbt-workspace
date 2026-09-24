Title: "xlibre: optionaler VNC-Server als generische Extension"
Category: active
Status: "assigned"
Assigned-To: "Galaxy"
Tags: "xlibre"

Optionaler VNC-Server als generische Extension in allen DDXen implementieren:

- X11 Protocol Extension fuer Configuration (Credentials Management, etc.)
- Flexibel genug fuer spaetere weitere Protokolle (z.B. RDP) ohne neuen
  Extension-Slot
- Generisches Design: Extension verwaltet mehrere Remote-Desktop-Protokolle
- VNC als erstes Protokoll, aber Architektur erlaubt zusaetzliche Protokolle
- Configuration via X11 Requests (nicht Kommandozeilen-Optionen)
- Credentials koennen dynamisch geaendert werden
- initiale configuration auch via cmdline
- optional zuschaltbar bei allen DDX'es
- damage tracking verwenden

Vorgehen:

* vor der eigentlichen implementation erstmal konzept erstellen und als starfleet-report einstellen (via starfleetctl)
* in separater branch und separatem worktree arbeiten -> via starfleetctl managen, nicht per git direkt worktrees anlegen
* immer nur in xserver-master clone arbeiten (aber separater worktree)
* niemals branches in der mpbt workspace wechseln!
* saubere einzel-commits
* wenn zuvor noch xserver-infrastruktur umgebaut werden muß (zb. zusätzliche
  callbacks), dann diese zunächst mit vorgeschalteten commits einführen
* kein direktes wrapping von ScreenRec proc vectors
* jedes commit muß einzeln sauber durchbauen (auch github CI verwenden)
