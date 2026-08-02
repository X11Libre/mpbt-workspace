Title: "transient model errors: no mail to flagship"
Slug: error-handling-1

Bei transienten model-errors, die sofortigen restart des prompt nach
sich ziehen (zb. "streaming response failed"), sollen keine messages
and flagschiff geschikt werden. Stattdessen nur ein entsprechendes
Status-Update im Board (damit wir zb. per web sehen was grad los ist),
toast im opencode-client (haben wir schon) und dann soll gleich ein
retry-gemacht werden (haben wir grad schon).
