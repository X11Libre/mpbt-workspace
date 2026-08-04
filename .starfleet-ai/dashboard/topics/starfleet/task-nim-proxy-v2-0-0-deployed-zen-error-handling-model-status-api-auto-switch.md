Title: "model-proxy: lokaler OpenAI-kompatibler Proxy in starfleetctl"
Category: starfleet
Kind: task
Status: "done"
Created-By: "Enterprise"
Created: "2026-08-03T18:19:43Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: starfleet/task-nim-proxy-v2-0-0-deployed-zen-error-handling-model-status-api-auto-switch

## Stand (2026-08-04, update 2)

### Model-Listing / Web-Auswahl (d2834db)

- `/v1/models` reicht jetzt die vollen Modell-Daten durch: id/object/created/
  owned_by direkt vom Upstream (nie aus models.yaml) + label/context/caps
  angereichert aus dem opencode-Katalog (`opencode models --verbose`, gecacht).
  NIM: 102 Modelle mit Labels (zB "DeepSeek V4 Flash", Context, Caps).
- `models sync` nimmt die Proxy-Backends in models.yaml auf
  (nim-proxy/<id>, zen-proxy/<id>) → Web-Console bietet sie zur Auswahl an
  (242 Modelle gesamt, davon 102 nim-proxy + 60 zen-proxy).
- Zen-Modelle (claude-fable-5 u.a.) haben keine Labels, da im opencode-Katalog
  unter diesen IDs nicht vorhanden (Upstream liefert nur Standardfelder).
