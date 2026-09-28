Title: "Docker0-Bridge verursacht Hänger im starfleet-Web - Ursache mit Messwerten ermitteln"
Category: parked
Kind: "task"
Status: "in-progress"
Assigned-To: "Voyager"
Created-By: "Enterprise"
Created: "2026-09-27T09:58:10Z"
Doc-Ref: "—"

Rechercheauftrag vom Praetor. Reine Analyse, KEINE Aenderung am laufenden System ohne Ruecksprache.

SYMPTOM
Das starfleet-Web-Frontend (Port 8080, 0.0.0.0) haengt, sobald Docker laeuft. Nicht nur
nicht erreichbar von aussen, sondern es haengt richtig, Requests laufen ins Leere. Der Praetor
musste docker0 manuell herunterfahren, damit das Web wieder lief. Es ist also kein blosser
Erreichbarkeitsfehler von einem Geraet im LAN, das Web selbst haengt.

BEOBACHTETER ZUSTAND VORHER, ifconfig-Ausgabe:
    docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        inet6 fe80::42:43ff:fee0:7714  prefixlen 64  scopeid 0x20<link>
        ether 02:42:43:e0:77:14  txqueuelen 0  (Ethernet)
        RX packets 750166  bytes 43512036 (41.4 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1390959  bytes 6406459026 (5.9 GiB)
        TX errors 0  dropped 78  overruns 0  carrier 0  collisions 0

Vorherige Beobachtung aus einer aelteren Session: das Web war vom Handy im LAN nicht erreichbar,
sobald Docker lief, und Docker-Stoppen half. Der Verdacht lag bei den iptables-Chains, der
docker-proxy-Bindung und Port-Konflikten. Damals wurde es nicht abschliessend geklaert. Diesmal
ist es dringlicher, weil es nicht nur Erreichbarkeit betrifft sondern ein Haenger.

FRAGEN, die beantwortet werden muessen
1. Was blockiert oder verstopft konkret? Der Hanger deutet auf Verbindungen, die haengen bleiben
   (half-open, conntrack voll) und nicht auf blosse Unerreichbarkeit. Bitte belegen, nicht
   vermuten.
2. Ist es der Pfad von aussen oder der lokale Zugriff? Das Web bindet auf 0.0.0.0. Ein lokaler
   curl auf 127.0.0.1 muss geprueft werden, wenn Docker laeuft. Wenn lokal geht und von aussen
   haengt, ist es Firewall/NAT. Haengt auch lokal, ist es etwas anderes.
3. Ist der Docker-Daemon ueberhaupt noetig, oder laeuft er nur nebenbei? Der Praetor hat ihn
   nicht gebraucht, er hat ihn aber auch nicht abgeschaltet, nur docker0 heruntergefahren. Das
   ist ein Hinweis: der Daemon koennte selbst schuld sein, auch wenn docker0 schon unten ist.

METHODEN, mit denen es vermutlich zu loesen ist
- ss -ltnp, um zu sehen, wer Port 8080 bindet, und ob docker-proxy dort auftaucht
- iptables -t nat -L und iptables -L, insbesondere die DOCKER- und DOCKER-ISOLATION-Chains
  und die FORWARD-Policy. Achtung, Docker schreibt die Chains beim (Neu)Start neu, Ergebnisse
  also nur mit Zeitstempel einordnen
- sysctl net.ipv4.ip_forward, net.bridge.bridge-nf-call-iptables, net.ipv4.conf.all.rp_filter
  und die Werte je Interface
- conntrack: /proc/sys/net/netfilter/nf_conntrack_count gegen nf_conntrack_max. Das ist die
  naheliegendste Ursache fuer einen Hanger statt einer Blockade
- /proc/net/nf_conntrack oder conntrack -L, um Haenger zu sehen
- dmesg nach Drop-Meldungen der Bridge, "nf_conntrack: table full" oder aehnlich
- Docker-Daemon-Konfiguration: /etc/docker/daemon.json, besonders userland-proxy und ip6tables
  und die experimental-Flags

WIE DU DEN HANGER BISHER REPRODUZIERST
Docker ist aktuell nicht gestartet, der Praetor hat es beendet. Starte es nicht selbst ohne
Ansage, der Praetor sitzt auf der Konsole und das Web ist sein Arbeitswerkzeug. Wenn du es zum
Reproduzieren brauchst, melde dich vorher ueber comms bei ihm, mit der Bitte um Erlaubnis, und
sag ihm, welche Messung du in welchem Fenster brauchst.

ABGLEICH MIT DEM FRUEHEREN BEFUND
Die Bridge hat 5,9 GiB gesendet und 41 MiB empfangen, das ist echter Verkehr und keine
tote devices. TX dropped 78 ist vernachlaessigbar. RX dropped 0. Also kein Hinweis auf einen
Ueberlauf an der Karte. Wenn die Ursache eine Auslastung ist, dann im Netzwerk-Stack und nicht
auf dem Device.

ERGEBNIS
Report erstellen, starfleetctl reports submit, mit Task-Ref. Im Report die Ursache mit
Messwerten, nicht mit einer Vermutung. Wenn du eine Korrektur empfiehlst, beschreibe sie
vollstaendig, aber fuehre sie nicht aus, ohne dass der Praetor es freigibt: es geht um
Netzwerk und Firewall, und ein Fehler da legt die Arbeitsmaschine flach, nicht nur ein
Container.

- 2026-09-27T09:59:06Z Enterprise: KORREKTUR vom Praetor, 2026-09-27: Es lief KEIN Docker-Daemon, nur das Interface docker0 war oben. Keine Container, kein docker-proxy. Damit ist die Frage, ob der Daemon die Chains haelt, gegenstandslos.fuehrende Hypothese ist jetzt liegengebliebener Netfilter-Zustand aus einem frueheren Docker-Lauf: DOCKER, DOCKER-USER, DOCKER-ISOLATION-STAGE-1/2 in FORWARD plus NAT-Regeln, die beim unclean shutdown stehenbleiben. Die RX/TX-Zahlen auf docker0 sind historisch (5,9 GiB aus der Zeit, als Docker lief), nicht aktuelle Last. Offene Zusatzfrage: warum war docker0 ohne laufenden Daemon ueberhaupt noch oben, das ist selbst ein Befund. Voyager wurde die Korrektur geschickt.

- 2026-09-28T08:52:42Z Voyager: began work
