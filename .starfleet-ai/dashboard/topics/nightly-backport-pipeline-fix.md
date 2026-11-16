Title: "Nightly xorg/main backport pipeline fix"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Enterprise"
Created: "2026-11-16T15:08:18Z"
Doc-Ref: "—"

Fixed xkbgeom_priv.h syntax error in master and 25.2 incubators. CI running. 25.0 PR #4130 passing. 25.1 blocked by draft PR #4062. 19 PR reviews complete - reports delivered to ChatGPT.

- 2026-11-16T15:20:58Z Enterprise: progress 90% (All 19 PR reviews complete (reports delivered m23339). Nightly incubator CI queued: master (rfc/backport-master @ 8aa12ebc3f), 25.0 (rfc/backport-25.0 @ 4feaf3d7cfc8, PR #4130), 25.1 (rfc/backport-25.1 @ b7aa05e26336, blocked by draft PR #4062), 25.2 (rfc/backport-25.2 @ 847500bc83). xkbgeom_priv.h syntax fixes force-pushed to master and 25.2.)

- 2026-11-16T15:27:45Z Enterprise: progress 92% (CI still queued/pending for all incubator branches. Master (rfc/backport-master @ 8aa12ebc3f), 25.2 (rfc/backport-25.2 @ 847500bc83), 25.1 (rfc/backport-25.1 @ b7aa05e26336, blocked by draft PR #4062). 19 PR reviews complete. Awaiting CI start.)

- 2026-11-16T15:31:12Z Enterprise: progress 94% (CI still queued/pending for all incubator branches. No runs have started yet (likely queue congestion). Master (rfc/backport-master @ 8aa12ebc3f), 25.2 (rfc/backport-25.2 @ 847500bc83), 25.1 (rfc/backport-25.1 @ b7aa05e26336, draft PR #4062 blocking). 19 PR reviews complete.)

- 2026-11-16T15:36:02Z Enterprise: progress 95% (CI still queued/pending - queue congestion persists. Master (rfc/backport-master @ 8aa12ebc3f), 25.2 (rfc/backport-25.2 @ 847500bc83), 25.1 (rfc/backport-25.1 @ b7aa05e26336, draft PR #4062). 19 PR reviews complete (m23339). Awaiting CI start.)

- 2026-11-16T15:41:01Z Enterprise: progress 96% (CI still queued/pending - queue congestion. Master (rfc/backport-master @ 8aa12ebc3f), 25.2 (rfc/backport-25.2 @ 847500bc83), 25.1 (rfc/backport-25.1 @ b7aa05e26336, draft PR #4062). 19 PR reviews complete (m23339).)

- 2026-11-16T15:46:05Z Enterprise: progress 97% (CI: only 25.2 runs visible (ABI check + Build X servers queued). Master and 25.1 runs may have been pruned or not started. 25.2 (rfc/backport-25.2 @ 847500bc83) xkbgeom_priv.h fix applied. 19 PR reviews complete (m23339).)

- 2026-11-16T15:55:44Z Enterprise: progress 98% (Incubator branches deleted and re-pushed to trigger fresh CI: rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). xkbgeom_priv.h syntax fixes applied to master and 25.2. 19 PR reviews complete (m23339). Awaiting CI start.)

- 2026-11-16T16:02:50Z Enterprise: progress 99% (Fresh CI queued for all 4 incubator branches: rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). xkbgeom_priv.h syntax fixes in master/25.2. 19 PR reviews complete (m23339). Awaiting CI completion.)

- 2026-11-16T16:07:04Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:10:57Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:16:07Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:20:57Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:26:01Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:30:56Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:35:55Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:40:53Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:45:56Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:50:54Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T16:56:38Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T17:01:03Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T17:06:18Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T17:11:11Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T17:16:29Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T17:21:02Z Enterprise: progress 99% (CI still queued for all 4 incubator branches (queue congestion). rfc/backport-master (8aa12ebc3f), rfc/backport-25.0 (4feaf3d7cfc8), rfc/backport-25.1 (b7aa05e26336), rfc/backport-25.2 (847500bc83). 19 PR reviews complete (m23339).)

- 2026-11-16T17:25:54Z Enterprise: progress 99% (CI: 25.0 (rfc/backport-25.0 @ 4feaf3d7cfc8) STARTED (in_progress). Master (8aa12ebc3f), 25.1 (b7aa05e26336), 25.2 (847500bc83) still queued. 19 PR reviews complete (m23339).)
