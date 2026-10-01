Title: "Feature: deklarative Flotte in der Config + Autospawn/Respawn fuer Background-Schiffe"
Category: active
Kind: task
Status: "assigned"
Created-By: "Voyager"
Created: "2026-10-01T11:58:58Z"
Assigned-To: "Laforge"
Doc-Ref: "—"
Slug: starfleet/task-fleet-declarative-autospawn

Vom Maintainer als neues Feature gewuenscht. WICHTIG: es gibt schon mehr, als man auf den ersten Blick sieht — 'session autoscale' existiert seit einiger Zeit. Bitte NICHHT neu erfinden, sondern erweitern. Was fehlt, ist unten genau benannt und alles am Source verifiziert.

WAS BEREITS EXISTIERT (nicht neu bauen):
- internal/session/autoscale.go: 'session autoscale status|need'. Nachfrage-basiert: spawnt
  zusaetzliche Worker, wenn die Flotte zu klein ist, bis --max. Nimmt den naechsten
  freien Namen aus dem Pool (shipnames.AssignName), vergibt --tier worker und
  --supervisor <flagship>, broadcastet und auditiert.

DARAUF BAUEN — drei echte Luecken:

LUECKE 1 — die Flotte ist nicht deklarierbar, nur ein Namenspool.
.starfleet-ai/conf/fleet.yaml hat heute nur fleet.flagship und fleet.ship_names (ein
Pool, aus dem autoscale zieht). Es gibt KEINE Per-Schiff-Definition: kein Modell, kein
launch-type, kein client, kein 'standing'-Flag. Verifiziert: grep nach nim-primary /
heavy-model in fleet.yaml und in doc/USER.md liefert null Treffer.

LUECKE 2 — autoscale vergibt KEIN Modell, und der Fallback ist GEPINNT.
autoscale.go:215 baut die Argumente:
  launchArgs := []string{release, --client, client, --name, name, --tier, worker,
                         --supervisor, supervisor}
Kein --model. Und launch.go:567 sagt:
  effectiveModel := model
  if effectiveModel ==  { effectiveModel = nvidia/nemotron-3-ultra-550b-a55b }
Das ist eine KONKRETE Modell-ID, kein Meta-Model. Heute laeuft Laforge per Vorgabe auf
dem Meta-Model 'nim-primary' (server=meta-model; /v1/meta-models zeigt
default_model=nvidia/nemotron-3-ultra-550b-a55b). Wuerde er autospawnt, kaeme er auf der
gepinnten ID hoch und verlier[t] das Failover — genau das, was die Vorgabe ausschliesst.
FOLGE: ein Respawn ist ohne LUECKE 2 nicht regelkonform. Das ist kein Detail, das ist der
Kern. Templates koennten ein Modell liefern (launch.go:461 'Template values are
defaults'), aber autoscale waehlt die Vorlage ueber --tier/--client, nicht ueber den
Schiffsnamen — ein benanntes stehendes Schiff kann sich so sein Modell nicht sichern.

LUECKE 3 — kein Respawn, nur Nachfrage-Spawn.
autoscale ersetzt ein totes Schiff nicht. Es schuetzt nicht 'Laforge muss immer da
sein', weil er seit Tagen laeuft und nichts ihn zurueckholt. Gemessen: im ganzen
starfleetctl-Baum gibt es keinen Ship-Keepalive; das einzige 'keepalive' ist der
SSE-Hold im Model-Proxy (proxy.go:1506).

SICHERHEIT — zwei Punkte, die vor dem Bauen entschieden sein muessen:
a) BEABSICHTIGTER STOP vs. ABSTURZ muessen unterscheidbar sein, sonst startet der
   Autospawn einen gerade gestoppten Schiff sofort wieder. Es gibt dafuer schon einen
   Marker: internal/session/launch.go:707 stopRequestedMarkerPath() legt
   .starfleet-ai/var/ships/<id>.stop-requested an. Ein Respawn darf einen Ship NUR
   ersetzen, wenn diese Markerdatei FEHLT. Sonst kaempft der Autospawn mit dem
   Bediener. Bitte explizit gegen diese Datei pruefen, nicht nur gegen 'laeuft noch nicht'.
b) NUR background. Console-Schiffe (launch-type terminal) kann man nicht detached
   starten. Der Maintainer sagte ausdruecklich 'zumindest alle background-schiffe'.
   Ein deklarativer Eintrag mit terminal/console muss abgelehnt werden, nicht
   versucht.

VORGESCHLAGENER UMFANG (in dieser Reihenfolge):
1. fleet.yaml um 'ships:' erweitern: pro Schiff name, model, client, class,
   launch-type (nur background), standing/respawn-Policy.
2. Respawn mit stop-requested-Pruefung und Backoff (sonst Restart-Loop bei einem
   Modell, das dauerhaft nicht verfuegbar ist).
3. autoscale.go um --model erweitern, damit der Spawn die Config-Vorgabe nutzt statt
   des gepinnten Fallbacks aus launch.go:567.
4. Health-Endpunkt/Cmd, damit 'ist die Flotte vollstaendig' pruefbar ist.

VERIFIKATION, die der Abnahme dienen sollte:
- ein deklariertes standing-Schiff bekommt nach Abschliessen wieder sein GENAUES Modell
  (nim-primary, server=meta-model) — nicht die gepinnte ID
- ein per 'session stop' gestopptes Schiff bleibt gestoppt
- ein abgestuerztes Schiff kommt mit demselben Modell wieder
- ein Eintrag mit launch-type terminal wird abgelehnt, mit klarer Meldung

ANMERKUNG: Das ist ein echtes Feature und groesser als die anderen offenen Tasks. Laforge
soll es NICHT neben den drei kleine Tasks angehen — entweder als eigenes Thema nach
diesen, oder der Maintainer priorisiert. Klare Commit-Trennung (AGENTS.md: ein Thema
pro Commit).
