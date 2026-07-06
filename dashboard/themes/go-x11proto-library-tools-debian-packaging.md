---
slug: go-x11proto-library-tools-debian-packaging
title: "go-x11proto library + tools + Debian packaging (**separate repo/project**)"
category: active
status: "**v0.0.7 released** (tag pushed 2026-07-01, ships `xnamespace -s`+manpage+JSON-removal)"
doc_ref: "repo `X11Libre/go-x11proto`, now an mpbt solution @ `_WORK_/go-x11proto/sources/xlibre/go-x11proto` (moved 2026-07-02 from the old `/home/nekrad/src/xorg/go-x11`); packaging `X11Libre/deb-pkg` `cf/repos/devuan/go-x11.yml`"
migrated_from: 8cf8692b9f0057ffe44e793b35bcf7329da83d3f
---

eventCh `send on closed channel` race fix + `%w` error-format fix (CI now shows the real socket errno instead of `%!w(...)`); Debianized into `golang-…-dev`/`xnamespace`/`tetris64`. **Tools get script-parseable output:** `xnamespace` has `-s/--short` (terse tab-separated, header-less, for shell/C `system()` — e.g. a DE launching a client into its own namespace); old `-json` mode dropped (−330 KB binary), `xnamespace-test` emits TAP. `xnamespace` also got a manpage (verified shipping in the `.deb`). `-s`+manpage+JSON-removal shipped in **v0.0.7**. The go-xts break on **PR #3199** is xserver-side (`-displayfd` socket collision), owned by agent `fix-pr3199-socket-race` — **not this repo**. Separate project/agent, coordinate via `agent-bus`. **xserver CI bump done:** `PKG_GOXPROTO_REF`/`GOXPROTO_REF` v0.0.4→**v0.0.7** (both sites, `.github/scripts/conf.sh` + `build-xserver.yml`) → **PR #3207** (2026-07-01, awaiting CI/merge)
