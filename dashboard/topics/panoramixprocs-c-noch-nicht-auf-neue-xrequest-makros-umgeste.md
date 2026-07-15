---
slug: panoramixprocs-c-noch-nicht-auf-neue-xrequest-makros-umgeste
title: "`panoramiXprocs.c` noch nicht auf neue `X_REQUEST*`-Makros umgestellt"
category: parked
noted_by: "praetor, 2026-07-02 (bei #3136 Bug-2-Audit aufgefallen)"
since: "2026-07-02"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

`Xext/panoramiX/panoramiXprocs.c` benutzt noch das alte Request-Handling (manuelles Header-Parsing, Byteswap, Längen-Checks) statt der neuen `X_REQUEST*`-Makros. **Außerdem prüfen:** sind die Replies dort schon auf den `x_rpcbuf_t`-Pfad (`X_SEND_REPLY_WITH_RPCBUF`) umgestellt, oder noch alte `WriteToClient`/`X_SEND_REPLY_SIMPLE`-Handler? (Beim Audit gesehen: `PanoramiXAllocColor` nutzt noch bare `xAllocColorReply` + `X_SEND_REPLY_SIMPLE` — Info-Leak, separat gefixt.) Eigener Umstell-Pass, wenn Zeit.
