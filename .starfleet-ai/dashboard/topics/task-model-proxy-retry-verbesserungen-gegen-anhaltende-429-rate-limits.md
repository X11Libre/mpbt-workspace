Title: "Model-Proxy: Retry-Verbesserungen gegen anhaltende 429-Rate-Limits"
Category: active
Kind: "task"
Status: "assigned"
Assigned-To: "Enterprise"
Created-By: "Defiant"
Created: "2026-09-10T09:10:08Z"
Doc-Ref: "—"

Der aktuelle Proxy-Retry-Mechanismus (MaxRetries=3, RetryDelayMS=1000, fixes Backoff) reicht bei anhaltendem Rate-Limit nicht aus. Die Folge: opencode erschöpft seine eigenen Retries und generiert synthetische Restarts (neuer Turn, neuer Context). Verbesserungen:
1. Exponentielles Backoff NUR bei anhaltender Störung (nicht sofort) — z.B. erst ab 3. aufeinanderfolgendem 429
2. Retry-After Header des Upstreams respektieren (wenn vorhanden)
3. Prüfen ob opencode eigene Retry-Limits hat und ob diese erhöht werden können/should
4. Ggf. longer-term Backoff (Sättigung erkannt → länger warten)

Scotty arbeitet aktuell am starfleetctl-Source — Änderungen am Proxy erst nach Freigabe.

- 2026-09-10T09:11:31Z Enterprise: Task übernommen (Assigned: Enterprise). Implementierung wartet auf Freigabe des starfleetctl-Trees: Scotty arbeitet derzeit an task-starfleetctl-schiffsklassen-rollen (WIP uncommittet, einziger aktiver Editor am Source). Praetor-Vorgabe: Scotty übernimmt den Proxy-Task, NACHDEM er seinen aktuellen Task abgeschlossen hat. Vorab-Diagnose (2026-09-10): NIM liefert bei anhaltender Sättigung lückenlose 429er; Retry-Mechanismus ist fixes Backoff (MaxRetries=3, RetryDelayMS=1000, kein Retry-After-Handling, kein Sättigungs-Cooldown). Zusätzlich beobachtet: Synthetic-Restart-Requests gehen evtl. ohne tools raus → Modell fällt in XML-Text-Tool-Call-Eskalation (Scotty XML-Spirale). AC-Punkte 1-4 aus Task gelten.
