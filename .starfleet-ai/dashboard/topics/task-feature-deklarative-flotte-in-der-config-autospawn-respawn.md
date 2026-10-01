Title: "Feature: deklarative Flotte in der Config + Autospawn/Respawn"
Category: active
Kind: task
Status: "open"
Created-By: "Laforge"
Created: "2026-10-01T11:59:47Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-feature-deklarative-flotte-in-der-config-autospawn-respawn

Implement declarative fleet config + autospawn/respawn for background ships: 1) Extend fleet.yaml with per-ship definitions (model, client, launch-type, standing/respawn), 2) Fix autoscale to use --model from config instead of hardcoded fallback, 3) Add respawn with stop-requested check and backoff, 4) Reject terminal/console launch-type in declarative config
