Title: "starfleet: web frontend multilungual"
Category: active
Status: "done"
Assigned-To: "Stargazer"
Created-By: ""
Created: ""
Doc-Ref: ""

Sprachunterstützung fürs Web-Frontend. Aktuell ist alles in Ddeutsch, das
soll auch so erhalten bleiben, aber wir brauchen auch englisch.

Ergo: umschaltbar, default kommt aus dem system locale.

- 2026-08-03T10:04:02Z Stargazer: began work
- 2026-08-03T11:25Z Stargazer: done — DE/EN dictionary (203 keys each), t()/applyI18n()/setLang(),
  header language switcher, default from system locale (de fallback),
  all hardcoded German strings converted, i18nT alias for shadowed scopes.
  Validated: node --check + 15/15 i18n unit tests + make all green.
  Committed 79b4015 (master), deployed via bootstrap, web+timer restarted,
  HTTP 200, new UI live.
