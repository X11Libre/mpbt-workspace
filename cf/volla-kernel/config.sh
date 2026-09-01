# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Config sourced by run-* scripts for the Volla kernel release line.
export XLIBRE_RELEASE="volla-kernel"
export PATH="$PATH:$HOME/go/bin"
export MPBT="mpbt-builder"

SOLUTION="cf/$XLIBRE_RELEASE/solutions/devuan.yaml"
WORKDIR="_WORK_/$XLIBRE_RELEASE"