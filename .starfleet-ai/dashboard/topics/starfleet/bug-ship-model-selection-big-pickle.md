Title: "bug: ship model-selection ignoriert --model (Scotty lief mit big-pickle)"
Category: active
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-10T09:09:29Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/bug-ship-model-selection-big-pickle

Beobachtet 2026-09-10: Scotty wurde via `session ship-run --name Scotty --model nvidia/nemotron-3-ultra-550b-a55b` gestartet, lief dann aber mit big-pickle (zen-proxy, verbraucht kostenpflichtiges Zen-Quota). --model-Flag und effectiveModel-Fallback in internal/session/launch.go (Zeile ~516-530) sind korrekt befüllt; Provider-Allowlist (enabled_providers, model-proxy-only) ist gesetzt. Verdacht: opencode wählt zur Laufzeit ein anderes Modell (Fallback auf Default/kleines Modell), z.B. weil per-ship models-Map bzw. Fallback-Metadaten (conf/models.yaml, z.B. `fallback:`) das angeforderte Modell umleiten, oder da nim-proxy Provider bei 429 direkt zurueckfaellt. Diagnose: verifizieren, warum opencode trotz explizitem --model mit big-pickle gestartet ist (Session-Log Scotty nach Restart pruefen, opencode Model-Selection-Logik / --print, models-map in der generierten Scotty.opencode.json). AC: ship-run gestartete Ships laufen garantiert mit dem angeforderten Modell und verbrauchen NICHT versehentlich das Zen-Quota.
