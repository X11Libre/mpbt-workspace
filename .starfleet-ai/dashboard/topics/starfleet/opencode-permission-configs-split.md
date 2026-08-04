---
title: "opencode: separate permission configs for foreground vs. background ships"
category: "active"
status: "done"
tags: "starfleet"
---

DONE (starfleetctl fb6982e, deployed via bootstrap).

Alle opencode-Ships bekommen jetzt über denselben Mechanismus eine
per-Ship-Config-Datei (`.starfleet-ai/var/ships/<id>.opencode.json`),
erzeugt von `generateOpencodeConfig()`:

- background/auto ships (`session ship-run`, web): deny ausserhalb workspace
- terminal ships (lokale Konsole, `starfleetctl run` / `run-opencode.*`):
  ask ausserhalb workspace, allow innerhalb
- `--unrestricted`: allow alles

Zuvor nutzte der Console-Pfad nur ein inline `OPENCODE_CONFIG_CONTENT`
(keine Datei, keine Permission-/Provider-Regeln). Der `run`-Pfad
(`--exec` und termctl) setzt jetzt `OPENCODE_CONFIG` auf die generierte
Datei; `OPENCODE_CONFIG_CONTENT` ist komplett entfernt. Zusätzlich setzt
die generierte Config jetzt `username` auf die Ship-ID (opencode fällt
sonst auf den OS-User zurück).

`generateOpencodeConfig()` ist damit der einzige
Config-Generierungspfad — Ansatzpunkt für die geplante
nim-proxy/zen-proxy-Provider-Injection (Enterprise, model-proxy-Feature).
