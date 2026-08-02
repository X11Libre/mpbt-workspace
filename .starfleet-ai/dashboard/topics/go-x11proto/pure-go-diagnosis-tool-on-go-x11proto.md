Title: "Pure-Go diagnosis tool (xdpyinfo-like) on go-x11proto"
Category: parked
Noted-By: "praetor idea, 2026-07-01"
Since: "2026-07-01"
Migrated-From: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
Slug: pure-go-diagnosis-tool-on-go-x11proto

Idea only, deprioritized. A pure-Go server-inventory dumper 
(setup: vendor/release/proto/byteorder; screens+depths+visuals; extensions+versions; pixmap-formats) 
built on go-x11proto — no libX11/libxcb, so it works in minimal/container/CI envs (where the go-xts socket issue lives).
Would ship with `-json`/`-s` from day one. Revisit if a pure-Go `xdpyinfo` is wanted
