Title: "Model-Health als Background-Service - Agent-Capability-Check + State-DB"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-17T15:08:35Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-model-health-als-background-service-agent-capability-check-state-db

# Model-Health-Background-Service (task)  ## Problem/Kontext - `model-proxy check` (Listing) + `--probe` (minimal 1-Token Chat) decken nur "ist im   Katalog + antwortet" ab. Ein Modell kann "served=true" sein (im Katalog) aber fuer   unseren Account unbrauchbar (z.B. nvidia/nemotron-4-340b-instruct -> "Not found for   account"). `--probe` ueber 158 Modelle sequentiell dauert >5min. - Es fehlt ein Test der Agent-Nutzbarkeit (Tool-Calls, Instruction-Following) fuer opencode.  ## Ziel 1. `--probe` als zeitgesteuerten Background-Job (Goroutine/Thread im Proxy-Daemon oder    separater Service, via autostart; Intervall konfigurierbar in model-proxy.yaml). 2. Ergebnis in einer State-DB (model-health.json erweitert oder eigener Store) erfassen:    served / reachable(probe) / agent_compatible(tool-call+instruction) / context / latenz /    timestamp; atomar schreiben. 3. Abfragbar fuer den Proxy (Strategie-Auswahl: nur gesunde Modelle) UND fuer Agents    (starfleetctl CLI / comms dispatch), sowie Web-Model-Dropdown. 4. Agent-Capability-Probe: Request mit tools-Def und "call e2e_check"-Instruktion ->    erwartet tool_calls in Antwort (genaue Definition siehe Implementierung). 5. Optionale Ergänzung aus LLM-Web-Recherchen (welche Modelle gelten als gut/sinnvoll).  ## Finales Ziel Uebersicht "welche Modelle sind gerade real fuer uns nutzbar" als Entscheidungsbasis fuer wiederkehrendes Strategie-Tuning (NIM-primary-Strategie etc).  ## Akzeptanz - Hintergrund-Check laeuft ohne Proxy-Neustart periodisch, schreibt State-DB. - Agents koennen den aktuellen Health-State per CLI abfragen. - Tool-Call-faehige vs nicht-faehige Modelle sind unterscheidbar. - Kein Benutzen gesperrter/benutzerunfaehiger Modelle in neuen Strategien. 
