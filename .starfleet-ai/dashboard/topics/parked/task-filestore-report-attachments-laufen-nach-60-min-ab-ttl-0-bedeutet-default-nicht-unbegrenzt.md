Title: "filestore: Report-Attachments laufen nach 60 Min ab - ttl=0 bedeutet Default, nicht unbegrenzt"
Category: parked
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-26T11:53:10Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: parked/task-filestore-report-attachments-laufen-nach-60-min-ab-ttl-0-bedeutet-default-nicht-unbegrenzt

Befund aus "Attached payload noch immer nicht im web sichtbar" (m123997).

URSACHE - Report-Anhaenge laufen nach 60 Minuten ab, und es gibt keine Option auf "laeuft nie"
internal/filestore/filestore.go:19   defaultTTL = 60 * time.Minute
internal/filestore/filestore.go:148  writeMeta: if ttl <= 0 { ttl = defaultTTL }
  Ein ttl von 0 bedeutet also NICHT "kein Ablauf", sondern "60 Minuten". Der Wert 0 ist als
  "unbegrenzt" lesbar und wird hier zum Default umgebogen.
internal/reports/run.go:160          reports submit --attachment ruft fstore.Put(path, 0) auf
  Der CLI-Pfad setzt also auf die falsche Semantik und bekommt 60 Min.
internal/web/web.go (apiStoreFile)   Web-Upload setzt ttl := time.Hour explizit, ebenfalls 60 Min
internal/filestore/filestore.go:106  Prune() loescht abgelaufene Dateien samt .meta

NEBENBEFUND - Web-Listen zeigt 0 Dateien
.starfleet-ai/var/files/ ist komplett leer (0 Eintraege). Konsistent damit, dass alles
abgelaufen und gepruned wurde. Es gibt derzeit keinen einzigen Report mit Anhaeng -
in allen 14 Reports fehlt das Feld attachments (omitempty, types.go:39).

BEWEIS, DASS DIE KETTE SONST FUNKTIONIERT
Comms-Anhaenge liegen in .starfleet-ai/var/comms/attachments/ und haben KEINE TTL:
  24 Dateien vorhanden, aelteste vom 24.09.
  Gegenprobe m123577__payload.txt: GET /api/store/m123577__payload.txt -> HTTP 200, 820 Bytes,
  sha256 stimmt mit dem Hash aus dem Message-Record ueberein
  (0536f77936c95b6bded6e0c8f76acf9572adde273f6d5661e474fdc185ce91b5).
  Der Store-Handler probiert erst den Filestore, dann comms/attachments als Fallback
  (internal/web/web.go:1740-1753). Gegenprobe unbekannter Name -> HTTP 404.
Der api-Feld attach ist in der Inbox auch vorhanden (24 von 79 Nachrichten), die Web-API
liefert es also korrekt. Es ist ausschliesslich die Lebensdauer der Datei.

NEBENBUG - Download-Button im Web
internal/web/index.html:2066
  window.open('/api/store/' + encodeURIComponent(name) + '&download=1', '_blank')
Zwei Fehler: (1) es fehlt das Fragezeichen, der Query-String ist ungueltig, (2) der
/api/store/-Handler unterstuetzt download gar nicht - nur /api/files/raw tut das
(internal/web/web.go:1860, 1889). Der Button liefert also stillschweigend die Inline-Ansicht.

VORSCHLAG
- writeMeta: 0 als "kein Ablauf" respektieren (z.B. ownExpires-Flag, damit die 60-Minuten-
  Default fuer kurzlebige Uploads intakt bleibt) und Reports-Anhaenge ohne Ablauf speichern.
- Web-Upload-Default entsprechend anpassen und/oder konfigurierbar machen.
- apiStoreFile: download-Parameter unterstuetzen (Content-Disposition: attachment) und den
  Bug in index.html:2066 auf ?download=1 korrigieren.
- Prune() sollte Report-Anhaenge nicht mitraeumen, wenn sie dauerhaft sein sollen.

NICHT AUSGEFUEHRT: Nichts geaendert, kein Fix committed. Der Anhaenge-Verlust ist nicht
rekonstruierbar - die Dateien sind weg, nur die Referenzen in den Message-Records existieren noch.
