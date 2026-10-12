Title: "model-proxy: Stream-Abbrüche durch Gesamt-Timeout (upstream stream interrupted before [DONE])"
Category: starfleet
Kind: task
Status: "done"
Assigned-To: "Defiant"
Created-By: "Defiant"
Created: "2026-10-12T10:19:21Z"
Doc-Ref: "—"

## Symptom

Alle Schiffe bekamen bei langen (Reasoning-)Streams abwechselnd:
  "model-proxy: upstream stream interrupted before [DONE]" (code stream_interrupted).
Der Stream brach ab, obwohl der Upstream noch lieferte.

## Root Cause

In `internal/modelproxy/proxy.go` (forwardChat) benutzte der Streaming-Pfad
denselben `http.Client` wie der Non-Streaming-Pfad:

    client := &http.Client{ Timeout: streamTimeout }   // streamTimeout = prov.Timeout

`prov.Timeout` default ist 30s (zen-proxy: 15s), siehe config.go. In Go deckt
`http.Client.Timeout` die GESAMTE Transaktion inkl. Lesen des Response-Bodys ab —
nicht nur den Verbindungsaufbau. Jeder SSE-Stream, der insgesamt länger als
15/30s lief, wurde daher beim Body-Read abgebrochen → `pipeSSE` sah EOF vor
`[DONE]` und emittierte `stream_interrupted`. Eingeführt mit `2f1140d0` (2026-10-09).

Nebenbefund: `b0374c1` fügte eine Keepalive-Goroutine hinzu, die `: keepalive`-
Kommentare parallel zum Haupt-Loop auf denselben `http.ResponseWriter` schrieb.
ResponseWriter/Flusher sind nicht nebenläufig-sicher → Datenrennen; zudem kann
ein Schreiben an den DOWNSTREAM den UPSTREAM nicht am Leben halten.

## Fix

- `04a8f03` (LaForge): getrennter Streaming-Client OHNE Gesamt-Timeout; Transport
  mit DialContext-Timeout 10s + ResponseHeaderTimeout 30s, Abbruch über `r.Context()`.
  Das ist der eigentliche Root-Cause-Fix.
- `7ce4c6f` (Defiant): racy Keepalive-Goroutine aus `b0374c1` entfernt; die
  Saturierungs-Keepalive läuft jetzt als `case <-keepaliveC:` in der EINEN
  Goroutine, die `w` besitzt. `stopKeepaliveTicker()` ersetzt sync.Once/Channel.
  Transport-Hygiene: Dialer.KeepAlive 5m→30s, IdleConnTimeout 0→90s.

## Deploy

`origin/master = 7ce4c6f` (gepusht) → `./starfleet-bootstrap` → `model-proxy restart`
(neue PID 18589). Kein web/timer-Restart nötig (model-proxy-only Änderung).

## Verifikation

- `/healthz` → {"ok":true}; `/v1/models` → 136 Modelle.
- Langer Stream via nim-proxy (`nvidia/nemotron-3-super-120b-a12b`, max_tokens 5000):
  Dauer **38,9s** (> 30s Default-Timeout), 1318 SSE-Chunks, Ende mit `data: [DONE]`,
  **KEIN** `stream_interrupted`.
  Mit dem alten Client (30s Gesamt-Timeout) wäre genau dieser Stream bei 30s abgebrochen.
- `gofmt -l`, `go vet`, `go test ./internal/modelproxy/` sauber; `make all` grün.

## Verwandt

- `starfleet/task-model-proxy-automatischer-fallback-bei-stream-abbruch-upstream-stream-interrupted`
  (LaForge) — die dort gewünschte Fallback-Logik ist eine Ergänzung; dieser Fix
  beseitigt die eigentliche Abbruchursache.
