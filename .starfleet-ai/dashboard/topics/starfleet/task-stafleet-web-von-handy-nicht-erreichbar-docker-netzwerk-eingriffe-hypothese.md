Title: "stafleet web von Handy nicht erreichbar - Docker-Netzwerk-Eingriffe (Hypothese)"
Category: starfleet
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-18T19:12:18Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: starfleet/task-stafleet-web-von-handy-nicht-erreichbar-docker-netzwerk-eingriffe-hypothese

Symptom: starfleet web (Port 8080) war vom Mobilphone nicht erreichbar; Docker stoppen hat geholfen.

Fakten:
- Web bindet 0.0.0.0:8080 (PID 19099), lokal 200 erreichbar.
- Docker-Daemon gestoppt; Kernel-Bridges bleiben: docker0, br-55b5e37a67c8, br-b5c31ac1770c (alle linkdown) + Routen 172.17/16, 172.18/16, 172.66/16.
- Kein Branch-Protection-Status; iptables-Root nötig fuer volle Auswertung.

Hypothesen:
1. Docker iptables (FORWARD DROP + userland-proxy docker-proxy 0.0.0.0-Bind) verdrängt/blokkiert Web-LAN-Traffic.
2. Port-Bind-Konflikt: Container mit -p Mapping auf 8080 oder LAN-seitig.
3. Docker FORWARD-Drop blockt externen LAN-Zugriff (Handy via Router).

Diagnose-Plan beim Wiederauftreten:
- vor Docker-Start: ss -ltnp | grep 8080
- Docker starten und sofort ss -ltnp -> docker-proxy/Container auf 8080?
- docker ps nach -p Mappings
- iptables (root): iptables -L FORWARD, iptables -t nat -L

Notiz: vmactions/netbsd-vm PR #3703 gemerged (separate story).
