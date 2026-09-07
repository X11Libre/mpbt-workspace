# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Config sourced by run-* scripts for the containerized devuan release line.
# All build stages run inside a container (see solutions/devuan.yaml ->
# container.image), with the whole workdir bind-mounted at the same path.
export XLIBRE_RELEASE="xserver-container"
export PATH="$PATH:$HOME/go/bin"
export MPBT="mpbt-builder"

SOLUTION="cf/$XLIBRE_RELEASE/solutions/devuan.yaml"
WORKDIR="_WORK_/$XLIBRE_RELEASE"
