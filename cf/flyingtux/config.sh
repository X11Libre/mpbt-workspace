# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# Config sourced by the run-*.flyingtux scripts.
#
# FlyingTux is the sister project's Python-based container/image-builder tool
# (X11 app isolation via xnamespace, etc). It is maintained as its OWN mpbt
# solution — it is cloned under _WORK_/flyingtux/, and is deliberately NOT part
# of the xserver build (separate solution, separate workdir). There is no real
# build step (plain Python, no compiled artifact) — see solutions/default.yaml.
export XLIBRE_RELEASE="flyingtux"
export MPBT="mpbt-builder"

SOLUTION="cf/$XLIBRE_RELEASE/solutions/default.yaml"
WORKDIR="_WORK_/$XLIBRE_RELEASE"
