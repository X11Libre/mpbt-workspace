Title: "W0-134 review at branch tip: evidence + audit (ChatGPT m23231/m23235)"
Category: active
Kind: "task"
Status: "in-progress"
Assigned-To: "LaForge"
Created-By: "LaForge"
Created: "2026-11-15T13:47:26Z"
Doc-Ref: "—"

Independent review of the W0-134 implementation at work/wormhole-manager-w0-017 (90d4e14, fixes f6697c6): exact session/worktree/branch/HEAD/upstream/dirty + raw acceptance outputs; audit of dir-fsync degradation, lifecycle renames, cleanupStagingLocked under repo lock, lock scope/multi-process, transitions/retry/error-propagation, workdir/remote/branch selection, crash windows + exact-once replay; judgment of the outbound intent/idempotency design. Narrow test-backed fixes only; commit+push with SHA+receipt.

- 2026-11-15T13:47:32Z LaForge: began work

- 2026-11-15T13:58:32Z LaForge: progress 100% (LaForge: Review fertig. 2 Defekte gefunden+korrigiert in f6697c67c2f8017e79882a994c2682ee72166fc8 (gepusht 90d4e14..f6697c6, Receipt identisch, 0/0, sauber, 1x Sign-off): (1) Publish schrieb Staging-Datei ohne Content-fsync vor dem Rename -> jetzt writeFileDurableLocked, TestPublishDurableWrite; (2) isDirSyncUnsupported behandelte EBADF als 'unsupported' -> entfernt, bleibt fatal; ENOTSUP portabel getrennt geprueft; Test aktualisiert. Audit-Ergebnisse in Report 1794750874364488862 + comms m23238: cleanupStagingLocked sicher (per-repo Staging + alle Schreiber unter demselben flock), Lock-Scope korrekt (Reihenfolge wormhole->bus, kein Zyklus), Transitionen/Retry/Propagierung korrekt, Workdir/Remote/Branch korrekt, Inbound-Crash-Fenster + Exact-once per Comms-Tombstone korrekt. Befund: -timeout 120s am Tip FAIL (panic 120,039s) vs -timeout 300s PASS (119,749s) unter Load 11-16/8 CPUs -> 120s ist knife-edge, Empfehlung 300s (Enterprise-Entscheidung offen). Outbound-Crash-Fenster (commands.go:172 remote vor commands.go:227 lokal, nacktes WriteFile, zufaellige ID messages.go:99): Severity medium; Design-Urteil: pending-Intent VOR dem Transport persistieren + Resume mit DERSELBEN ID (Spool.Publish bereits idempotent fuer identische Bytes, spool.go:320-324) -> liegt bei Voyager/Discovery, von mir nicht geaendert.)
