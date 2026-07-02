# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Config sourced by the run-*.go-x11proto scripts.
#
# go-x11proto is the Go X11-protocol client library + tools (xnamespace, the
# go-xts conformance client). It is maintained as its OWN mpbt solution — it is
# cloned (and optionally built via its Makefile) under _WORK_/go-x11proto/, and
# is deliberately NOT part of the xserver build (separate solution, separate
# workdir). All agent work on go-x11proto now happens under this workspace.
export XLIBRE_RELEASE="go-x11proto"
export PATH="$PATH:$HOME/go/bin"
export MPBT="mpbt-builder"

SOLUTION="cf/$XLIBRE_RELEASE/solutions/default.yaml"
WORKDIR="_WORK_/$XLIBRE_RELEASE"
