Title: "wip/screenlist: ConnectionInfoSize durch rpcbuf-Globale abloesen"
Category: active
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-29T13:33:02Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-wip-screenlist-connectioninfosize-durch-rpcbuf-globale-abloesen

Folge-Commit auf Branch wip/screenlist (Branch liegt auf origin, SHA 06a49d4414. Der Worktree _WORK_/worktrees/xserver/screenlist wurde am 2026-10-07 entfernt - vor Fortsetzung neu anlegen, z.B. via `starfleetctl worktree add <repo> <name> --branch wip/screenlist`). ConnectionInfoSize als separate globale Groesse entfaellt; stattdessen eine globale x_rpcbuf_t, die den Connection-Setup-Block haelt. ConnectionInfo bleibt weiterhin maintained und zeigt auf denselben Puffer (im aktuellen Baum heisst das Feld 'buffer', NICHT 'data' - rpcbuf_priv.h:33). Aufrufer in dix/dispatch.c (.length = bytes_to_int32(ConnectionInfoSize), dixWriteToClient(client, ConnectionInfoSize, ...), WriteSConnectionInfo) und dix/connsetup.c (dixNewConnectionInfoBlock) auf .buffer/.wpos umstellen. Hintergrund: die in PR #3765 gemessene Diskrepanz - PanoramiXCreateConnectionBlock() gibt wpos (Laenge von Screen 0) zurueck, waehrend der ueberschriebene Inhalt nur 'length' (Schnittmenge) betraegt; mit einer echten rpcbuf-Globalen ist der Puffer+waechsende Position eine Einheit und die Fehlerklasse verschwindet.
