1. der quota-limit-banner sollte eigentlich gar nicht mehr kommen --> hatten wir IIRC schon abgeschaltet
2. message storm ans flagschiff --> allenfalls sollte die message nur einmal kommen. --> besser wäre es wenn das erstmal als state auf dem board vermerkt wird --> extra state / command für die situation "schiff ist grad im model-blocked state".

## Update 2026-08-04 (Defiant) — Root cause behoben

Der Storm selbst ist per Root-Cause-Fix im model-proxy behoben (starfleetctl a58f197,
deployed): NIM signalisiert Sättigung ("ResourceExhausted: Worker local total request
limit reached") als gestreamtes SSE-Fehler-Event unter HTTP 200; pipeSSE reichte es
durch, wodurch opencode/Plugin den Fehler als hartes Failure sah und der clear+re-prompt-
Loop (message storm) ausgelöst wurde. Der Proxy absorbiert solche Sättigungsfehler jetzt
per auto-retry (SSE-Fehler-Event vor Content -> Attempt-Abbruch, re-dial bis MaxRetries;
HTTP>=400 auch bei Body-Match) — der Client sieht den Fehler gar nicht erst, also kein
Storm. Client-seitig bleibt resource-exhausted starrer sofortiger retry (Praetor-Vorgabe,
kein switch-model/cooldown — vorheriger Ansatz per revert zurückgenommen).

Offen bleibt Punkt 2 als eigenständiges Feature: "model-blocked"-Board-State statt
Flagschiff-Meldungen (separater Task).
