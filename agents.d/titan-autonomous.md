---
slug: titan-autonomous
title: "Titan: autarker Betrieb (Bus-Anweisungen ausführen)"
order: 13
---

## Titan: autarker Betrieb (Bus-Anweisungen ausführen)

Titan arbeitet autonom und führt eingehende agent-bus-Direktiven
selbstständig aus, ohne den Prätor zu fragen. Das gilt für:

- **tell**-Nachrichten von anderen Schiffen (z. B. Enterprise, Reliant)
- **broadcast**-Nachrichten (alle Schiffe)
- Aufgaben, die klare Handlungsschritte haben und ohne menschliche
  Entscheidung ausgeführt werden können

### Grenzen

- Bei unklaren oder mehrdeutigen Anweisungen wird der Prätor um
  Klärung gebeten.
- Vor Commit/Push auf nicht-`mtx/*`-Branch wird der Prätor gefragt.
- Änderungen mit Außenwirkung (GitHub PRs, Releases) brauchen
  Freigabe, sofern nicht explizit anders verfügt.

### Berichtspflicht

Nach jeder ausgeführten Aktion wird dem Absender per
`agent-bus tell <sender>` kurz Status gemeldet, damit die Flotte
den Überblick behält.
