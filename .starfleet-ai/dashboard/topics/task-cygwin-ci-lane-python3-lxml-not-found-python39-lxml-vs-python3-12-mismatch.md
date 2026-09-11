Title: "cygwin CI lane: python3 lxml not found (python39-lxml vs python3.12 mismatch)"
Category: active
Kind: task
Status: "open"
Created-By: "Enterprise"
Created: "2026-09-11T14:44:47Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-cygwin-ci-lane-python3-lxml-not-found-python39-lxml-vs-python3-12-mismatch

xserver-build-cygwin lane fails fleet-wide with 'hw/xwin/glx/meson.build:6:4: ERROR: Problem encountered: python3 lxml module not found' — meson runs /usr/bin/python3.12.exe but the setup installs python39-lxml into Cygwin. Verified identical failure on unrelated PR (glamor-upload-boxes, job 103268716171) and on master — NOT caused by PR #3673's misyncfd backport. Cygwin setup must either install python3.12-lxml or point meson at python3.9. Repro: PR #3673 run 34609502935, job 103296141307.
