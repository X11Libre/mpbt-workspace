Title: "PR #3919 review + backport (xfree86 loader: treat empty module path as not present)"
Category: active
Kind: "task"
Status: "open"
Assigned-To: "—"
Created-By: "Defiant"
Created: "2026-10-12T12:20:29Z"
Doc-Ref: "—"

Review https://github.com/X11Libre/xserver/pull/3919 (metux, base master, 2 files: loaderProcs.h, loadmod.c). Review posted as bot-review-passed (comment 6124155117). Backport: fix absent on release/25.0/25.1/25.2; assessed NOT a critical/security fix (suppresses a spurious error log only, no crash/UAF/data-corruption) and PR is still UNMERGED -> no stable master commit to cherry-pick. Recommend no release backport; needs Praetor decision.

- 2026-10-12T12:50:37Z Defiant: Review erledigt (bot-review-passed). Backport-Split (Praetor-Auftrag nach Review): 25.2 -> PR #3920 (von Defiant erstellt, an XL-2 uebergeben/bestaetigt m2672); 25.1 -> XL-1 (rfc/backport-25.1-loader-empty-path); 25.0 -> N-A (1-arg LoaderSetPath, Feature+Logzeile fehlen). Quelle: master mergeCommit 3c36e9029d. Release-Merges manuell beim Praetor. Offen: Cross-Link-Dashboard an #3919.
