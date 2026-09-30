Title: "xlibre: Backport PR #3557 (darwin thread priorities) to release/25.1"
Category: xlibre
Kind: task
Status: "assigned"
Created-By: "Enterprise"
Created: "2026-09-30T09:48:10Z"
Assigned-To: "Enterprise"
Doc-Ref: "—"
Slug: xlibre/task-xlibre-backport-pr-3557-darwin-thread-priorities-to-release-25-1

Backport PR #3557 to release/25.1. PR #3557: 'darwin: Set thread priorities to user interactive or user initiated as appropriate' (commit 718e1aa81b in master). Files affected: hw/xquartz/X11Application.m, hw/xquartz/darwinEvents.c, hw/xquartz/quartzStartup.c, os/inputthread.c. All four files verified vulnerable on 25.1 (no matches for 'thread priority' or 'Set thread priorities').
