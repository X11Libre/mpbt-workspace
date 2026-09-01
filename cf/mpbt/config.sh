# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Config sourced by the run-fetch.mpbt and run-build.mpbt scripts.
#
# mpbt is the build tool itself (mpbt-builder). It is maintained as its OWN
# mpbt solution — it is cloned (and built via its Makefile) under
# _WORK_/mpbt/, and is deliberately NOT part of the xserver build.
export PATH="$PATH:$HOME/go/bin"
export MPBT="mpbt-builder"

SOLUTION="cf/mpbt/solutions/default.yaml"
WORKDIR="_WORK_/mpbt"
