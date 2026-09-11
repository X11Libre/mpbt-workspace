# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Config sourced by the run-*.starfleetctl scripts.
#
# starfleetctl is the fleet-coordination tool (comms, tasks, dashboard,
# sessions, timing). It is maintained as its OWN mpbt solution — it is
# cloned (and optionally built via its Makefile) under _WORK_/starfleetctl/,
# deliberately separate from the xserver/other builds. All larger work on
# starfleetctl (branches, worktrees) happens under this solution.
export XLIBRE_RELEASE="starfleetctl"
export PATH="$PATH:$HOME/go/bin"
export MPBT="mpbt-builder"

SOLUTION="cf/$XLIBRE_RELEASE/solutions/default.yaml"
WORKDIR="_WORK_/$XLIBRE_RELEASE"