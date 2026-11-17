Title: "starfleet: bug: web: nach ship-launch ist das formularfeld für model nicht mehr vorausgewählt"
Category: starfleet
Kind: "task"
Status: "done"
Assigned-To: "LaForge"
Created-By: "Aeon"
Created: "2026-09-04T17:27:30Z"
Doc-Ref: "—"

Beim normalen Laden ist im Formularfeld zum Ship-Launch ein Model vorausgewählt (aktuell zb nemotron), sodaß man einfach auf den button clicken kann und neues schiff wird gestartet. wenn man das tut, verschwindet aber (beim dadurch getriggerten reload) die vorauswahl, sodaß bei erneutem click kein schiff mehr direkt gestartet werden kann (man muß dann erst explizit ein model auswählen, damit es wieder geht). macht man ein browser-reload, dann ist die vorauswahl wieder da.

- 2026-11-17T17:22:12Z LaForge: FIXED+VERIFIED: gefixt durch cbba3ae (2026-09-19), in origin/master + deployed web (vcs.revision=cfe3075). Headless-Chromium-Probe (_WORK_/starfleetctl/tmp/probe-nsmodel.mjs) gegen live Konsole 127.0.0.1:8080: fleet_model=heavy-model ueberlebt shipLaunch-Pfad (refresh+await loadModels()) UND Page.reload; frischer Profil-Load zeigt 90 Optionen ohne Vorauswahl (localStorage leer); 0 JS-Exceptions.

- 2026-11-17T17:22:16Z LaForge: completed
