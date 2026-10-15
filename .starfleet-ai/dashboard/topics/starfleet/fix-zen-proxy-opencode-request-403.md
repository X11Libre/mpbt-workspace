Title: "Fix Zen free-tier 403 — stop synthesizing x-opencode-request"
Category: active
Kind: "task"
Status: "done"
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: "2026-10-15T09:30:00Z"
Doc-Ref: "—"

## Summary
Follow-up to `starfleet/task-analyse-wip-fix-zen-session-header` (629e115 + bde09ae). That
work fixed the Zen free-tier header gate (session headers + UA) and body gate (tools
injection). A residual HTTP 403 `FreeTierError` remained and was traced to a **third,
independent factor**: the proxy was *synthesizing* `x-opencode-request`.

## Root cause
`applyUpstreamHeaders` (internal/modelproxy/config.go) forged a request id when the client
did not supply one:

    up.Header.Set("x-opencode-request", "msg_"+randHex(16))   // 32 lowercase hex

Zen validates the **format** of `x-opencode-request` when the header is present; a fabricated
`msg_`+32-hex value is rejected with **HTTP 403 FreeTierError**. The official opencode client
does **not** send this header at all (confirmed by intercepting direct opencode→Zen traffic).

Decisive single-factor drop tests against the live gateway: removing *only*
`X-Opencode-Request` turned a 403 into a 200; a valid 26-char id also gave 200; 32-hex/invalid
gave 403; empty string gave 200. Client/Project/session headers, HTTP/2 vs 1.1, and the body
were ruled out as causes.

## Fix
Commit **f267f92** `fix(model-proxy): never synthesize x-opencode-request for Zen`
- `internal/modelproxy/config.go`: forward a client-supplied `x-opencode-request` verbatim
  when present, otherwise send nothing — never forge one. Doc comment updated.
- Removed the now-unused `randHex` helper and its `crypto/rand`, `encoding/hex`, `strconv`
  imports.
- `internal/modelproxy/config_test.go`: test table now asserts verbatim forwarding
  (`wantRequest`), incl. a case that the header is never synthesized.

## Verification
- `make all` green; `go test -count=1 ./internal/modelproxy/` green.
- Isolated proxy against real Zen: client header shape (no `x-opencode-request`) → **200**;
  forged `msg_…` id → **403 FreeTierError**.
- Deployed via `./starfleet-bootstrap` + `model-proxy restart`; live `:8443` daemon
  (pid 17052) confirmed on `f267f92` via `/proc/17052/exe`.
- Live E2E: `POST :8443/v1/chat/completions` model `big-pickle` → **HTTP 200**, SSE,
  terminated with `[DONE]`; no 403/FreeTier in the proxy log.

## Refs
- github: `bde09ae..f267f92` master→master
- precursor: `starfleet/task-analyse-wip-fix-zen-session-header`
- distinct billing/quota blockage (still Praetor-pending) tracked separately in
  `starfleet/model-api-blockiert-nim-zen`
- source owner notified: comms m1258 → LaForge

## Addendum — exakte Grammatik von `x-opencode-request` (am Live-Gateway vermessen, 2026-10-15)
Wenn der Header **nicht-leer** gesetzt ist, akzeptiert Zen nur:

    ^msg_[0-9a-f]{12}[0-9A-Za-z]{14}$      (msg_ + 12 Klein-Hex + 14 Base62, Wertlänge 30)

Jeder andere nicht-leere Wert → `403 FreeTierError`; **leer** (`""`) oder **abwesend** → 200.
Grenzwerte gemessen: Länge exakt 26 nach Präfix (24/25/27/28 → 403); ≥12 führende Klein-Hex
(11 → 403, 12 → 200); Groß-Hex A–F → 403; nur `msg_` → 403; frischer Zufallswert in korrekter
Form → 200 (kein Replay-Schutz). Der Proxy-Alt-Wert `msg_`+32-Hex (`req_24`) fiel genau
deshalb durch. Vollständige Messreihe: Report
`r-1792059708782965624@starfleet` („…x-opencode-request — exakte Grammatik…").
Optionaler Härtungsschritt (nicht umgesetzt): verbatim-Weiterleitung nur, wenn der Wert dem
Muster entspricht — sonst verwerfen, statt den Client in einen 403 laufen zu lassen.
