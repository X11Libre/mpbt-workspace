Subject: "starfleet: web -> timer: button um timer sofort auszuführen"
Category: starfleet
Kind: "task"
Status: "done"
From: "McKinley"
Date: "2026-09-11T16:31:48Z"
Doc-Ref: "—"

in starfleet web: in der timer list einen button pro timer, um ihn sofort auszuführen.

- 2026-09-17T15:00:00Z Scotty: **IMPLEMENTIERT**:
  - Backend: Neuer Endpoint `POST /api/timer/{id}/run` in `internal/web/web.go` (`timerRunNow` Funktion)
    - Setzt `NextFire` auf `time.Now().Unix()` (sofort fällig)
    - Aktualisiert Timer im Store
    - Sendet SIGHUP an Timer-Worker (`timer.NotifyWorker`) für sofortigen Poll
  - Frontend: "Jetzt ausführen" / "Run Now" Button in Timer-Liste (`internal/web/index.html`)
    - Nur für aktivierte Timer sichtbar (neben Pause/Resume)
    - JavaScript Funktion `timerRunNow(id)` ruft Endpoint auf
    - i18n Strings für DE/EN hinzugefügt (timer.pause, timer.resume, timer.run_now, timer.run_now.suffix)
  - Build: `make` läuft sauber durch (alle Tests grün)
