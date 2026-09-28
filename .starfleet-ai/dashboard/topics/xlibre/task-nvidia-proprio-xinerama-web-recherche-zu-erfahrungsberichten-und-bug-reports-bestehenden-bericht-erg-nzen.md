Title: "NVIDIA-proprio + Xinerama: Web-Recherche zu Erfahrungsberichten und Bug-Reports, bestehenden Bericht ergänzen"
Category: xlibre
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-28T09:17:44Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: xlibre/task-nvidia-proprio-xinerama-web-recherche-zu-erfahrungsberichten-und-bug-reports-bestehenden-bericht-erg-nzen

Ergaenzungsauftrag von McKinley zum bereits abgeschlossenen Task
xlibre/task-nvidia-proprio-xinerama-unterst-tzte-treiberversionen-ermitteln-und-abgleichen
und zum Bericht r-1790496160019163169@starfleet.

BISHERIGER BEFUND, rein statisch und ohne Laufzeittest:
Alle vier von XLibre unterstuetzten Treiberversionen 390.157, 470.256.02, 550.142 und 570.133.07
importieren identisch genau zwei PanoramiX-Symbole, noPanoramiXExtension und
PanoramiXTranslateVisualID, und XLibre exportiert beide. Keine versionsspezifische ABI-Barriere.
390.157 referenziert zusaetzlich den String PanoramiXVisualTable, den aber weder XLibre noch
Upstream xorg/main bereitstellt, also keine Regression.

WAS FEHLT UND JETZT ERARBEITET WERDEN SOLL:
Bisher wurde nichts aus der Praxis belegt. Gesucht sind Erfahrungsberichte und Bug-Reports aus
der Praxis, also:
1. Funktioniert der proprietaere NVIDIA-Treiber mit Xinerama tatsaechlich, und wenn ja, unter
   welchen Bedingungen?
2. Welche bekannten Symptome und Fehlerbilder gibt es, zum Beispiel schwarze Fenster, falsche
   Geometrien, abgeschaltete Screens, Leistungseinbusse, fehlschlagendes Composite, Rand-Rendering
   oder Rauschen auf geteilten Screens?
3. Gibt es Versionsabhaengigkeiten, die meine statische Analyse nicht sehen kann, weil sie zur
   Laufzeit auftreten und nicht ueber Symbole?
4. Was ist der gangbare Weg, PanoramiX mit NVIDIA zu betreiben, und welche Stolperfallen sind
   dokumentiert?
5. Gibt es Reports, die meinen Befund widerlegen oder relativieren, insbesondere zu 390.157 und
   PanoramiXVisualTable?

METHODE
Web-Recherche. Quellen mit Datum und Version nennen, Forumsaussagen klar als Aussage kennzeichnen
und von Messungen trennen. Wenn etwas nur Einzelfallbericht ist, das auch so schreiben.

ERGEBNIS
Den bestehenden Bericht r-1790496160019163169@starfleet ergaenzen, nicht einen neuen daneben
erfinden, und klar sagen, was die Recherche an der statischen Analyse aendert oder nicht.
Widersprueche ausdruecklich nennen, auch wenn sie unbequem sind. Statt "nichts gefunden" lieber
schreiben, welche Quellen man nicht erreicht hat, zum Beispiel weil sie Login oder JavaScript
brauchen.
