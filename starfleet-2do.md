[ ] bug: attached ship -> crash nach terminal-close
[ ] prüfen: separates data dir pro schiff (  "data.directory": "/your/custom/path/to/.opencode")
[ ] model-proxy: logging --> kommen schiffskennungen sauber durch ?
[ ] model-proxy: schiffs-status tracken
[*] committer name / mail & signoff fixen
[*] auto-restart funktioniert schon wieder nicht mehr.
[*] ZEN splash screen / auto-retry über proxy abfangen
[ ] config option: nur noch proxy models zeigen (in der auto-generierten config)

## xorg-Backport-PRs mit roter CI (2026-10-01, Voyager)

Nicht reviewen, nicht mergen. Erst reparieren, dann wieder aufnehmen.
Diagnose unten ist gemessen, nicht vermutet.

[#3780] meson.build NICHT BALANCIERT — 2 nicht geschlossene `if`
  if: 105 / endif: 103   (master dagegen 103/103)
  Betroffen sind genau die beiden Guards, die der Repair-Commit
  "Fix backport regressions introduced by the 3983c7408c cherry-pick" schliessen sollte:
      Zeile 335:  if int10 == 'auto'
      Zeile 628:  if (get_option('linux_acpi') == true and
  CI-Fehler ist entsprechend `meson.build:984:42: ERROR: Expecting endif got eof.`
  Der Repair hat offenbar die doppelten INNEREN if-Zeilen entfernt, die zugehoerigen
  endif fuer die AEUSSEREN if aber nicht wiederhergestellt — oder der Repair steckt in
  diesem Branch gar nicht. In diesem Zweig steckt zwar
  `cpu_family() in ['ppc', 'ppc64']`, die Bilanz stimmt trotzdem nicht.
  ARBEIT: im PR-Branch die beiden endif ergaenzen bzw. die Guards so kollabieren, dass
  if/endif aufgeht. Vorsicht: dieselbe Fehlerklasse hat schon einmal zugeschlagen und ist
  im Backport-Skill dokumentiert.

[#3787] Zwei unabhaengige Maengel
  1) `Check Signed-Off-By` schlaegt fehl — bestaetigt die Review: die Zeile fehlt im
     Commit. Autor lautet `Ben Song <bensongsyz@gmail.com>`, steht als Author: drin.
  2) 3 qemu-user-Lanes rot: armhf, mipsel, ppc64el
  Review-Kommentar steht, Label ist bot-review-changes-requested. Code ist inhaltlich ok.

[#3778] 4 qemu-user-Lanes rot: alpha, armhf, ppc64el, sparc64
  Achtung: traegt bot-review-passed OHNE Review-Kommentar — Label ist ungueltig, weil
  beim Labeln die CI gar nicht geprueft war. Erst CI, dann neu labeln.

HINWEIS zur Einordnung: die qemu-user-Lane ist NICHT defekt. #3772 und #3783 haben alle
fuenf qemu-Jobs gruen. Die Fehler sind also PR-spezifisch, nicht Infra.
Das stuetzt die Absicht, diese drei zurueckzustellen statt die Lane zu suspectieren.

Werkzeug-Mangel, der dabei aufgefallen ist: `starfleetctl github pr job-logs` ist auf
gh 2.46 kaputt, es ruft `gh api --follow-redirects` auf und das Flag gibt es dort nicht.
Job-Logs muss man derzeit direkt holen:
  curl -sL -H "Authorization: Bearer $(gh auth token)" \
    "https://api.github.com/repos/X11Libre/xserver/actions/jobs/<jobid>/logs"
