#!/bin/bash
#
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# agent-bus-processor.sh — watches the agent-bus message directory for
# directives addressed to this ship and injects them into the ship's opencode
# session via `opencode run --session <session-id>`, bypassing the need for
# tmux or plugins.
#

AGENT_ID="${AGENT_ID:?AGENT_ID is required}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUS_DIR="${BUS_DIR:-$ROOT/_WORK_/agent-bus}"
MSG_DIR="$BUS_DIR/msgs"
ACK_DIR="$BUS_DIR/acks"
LOGDIR="$BUS_DIR/logs"
SELF="$AGENT_ID"

# Ensure opencode is in PATH
PATH="/home/nekrad/.local/bin:$PATH"
export PATH

# Only one processor per agent
LOCKFILE="$BUS_DIR/processor-${SELF}.lock"
exec 8>"$LOCKFILE" || exit 1
flock -n 8 || exit 0

# Redirect all output to agent-specific log file.
mkdir -p "$LOGDIR"
exec >> "$LOGDIR/processor-${SELF}.log" 2>&1

echo "processor: started for $SELF on $(date)"

# Helper: get the session ID of the running opencode session for this ship.
get_session_id() {
  opencode session list --format json 2>/dev/null |
    python3 -c "import sys,json; ss=json.load(sys.stdin); ms=[s for s in ss if s.get('title')=='$SELF']; print(max(ms, key=lambda s: s.get('updated',0))['id'] if ms else '')" 2>/dev/null || true
}

while :; do
    sess_id=$(get_session_id)
    if [ -z "$sess_id" ]; then
      echo "processor: no session found for $SELF"
      sleep 5
      continue
    fi

    shopt -s nullglob
    for f in "$MSG_DIR"/m*.tsv; do
        [ -e "$f" ] || continue
        id="$(basename "$f" .tsv)"
        ackFile="$ACK_DIR/${id}__${SELF}"
        [ -f "$ackFile" ] && continue
        IFS=$'\t' read -r epoch isots from to what < "$f" || continue
        [ "$to" != "all" ] && [ "$to" != "$SELF" ] && continue

        echo "processor: acking $id"
        : > "$ackFile"

        echo "processor: injecting $id into session $sess_id: $what"
        timeout 5 opencode run -s "$sess_id" -c "$what" 2>&1 || echo "processor: inject failed for $id (exit $?)"
        echo "processor: done $id"
    done
    sleep 2
done
