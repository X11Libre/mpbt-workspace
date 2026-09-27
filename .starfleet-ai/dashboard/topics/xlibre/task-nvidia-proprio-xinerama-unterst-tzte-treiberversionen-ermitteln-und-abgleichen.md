Title: "NVIDIA-proprio + Xinerama: unterstützte Treiberversionen ermitteln und abgleichen"
Category: xlibre
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-27T07:56:45Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: xlibre/task-nvidia-proprio-xinerama-unterst-tzte-treiberversionen-ermitteln-und-abgleichen

Rechercheauftrag von McKinley: Funktionieren die proprietären NVIDIA-Treiber zusammen mit
Xinerama? Die einzelnen von XLibre unterstützten Versionen auflisten und abgleichen.

FRAGEN
1. Welche Versionen der proprietären NVIDIA-Treiber unterstützt XLibre überhaupt, und wo ist
   diese Liste belegt (nicht geraten)?
2. Funktioniert jede dieser Versionen mit Xinerama, und woran hängt es? Xinerama wird in
   modernen Xorg von PanoramiX bereitgestellt, der Treiber registriert seine Screens bei
   PanoramiX. Entscheidend ist, ob der jeweilige Treiber das tut und ob die vom X-Server
   benötigten Symbole vorhanden sind.
3. Je Version ein belegtes Ergebnis, nicht eine Vermutung. Wenn eine Version nicht empirisch
   geprueft ist, das auch so kennzeichnen und sagen, worauf sich die Aussage stuetzt.

METHODEN, die zur Verfuegung stehen
- Skill nvidia-abi als lebender Record empirischer Befunde
- scripts/nvidia-abi-check zur Klassifizierung von Symbolen gegen die NVIDIA-Blobs
- scripts/driver-tracker fuer den Versionsabgleich
- scripts/fetch-nvidia-drivers zum Besorgen der .run-Installer, falls noetig
- der xserver-Quellbaum, insbesondere Xext/panoramiX und hw/xfree86/compat mit den
  NVIDIA-Xorg-Config-Fragmenten

WICHTIG
- Nichts am xserver-Source aendern, das ist eine reine Recherche
- Keine Dateien in Source-Baeume legen, Vergleichs-Dumps nach _WORK_/<projekt>/tmp/
- Ergebnisse mit konkreter Quelle, nicht mit Bauchgefuehl
- Abschluss als starfleet-Report, damit die Antwort dauerhaft auffindbar ist
