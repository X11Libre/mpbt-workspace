#!/usr/bin/env bash
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# agent-bus-auto-id.sh — auto-assign a Star Trek ship name as $STARFLEET_SHIP_ID
# whenever an interactive shell is sitting inside this workspace tree, so a
# plain `claude` (or opencode, or anything else) launched here registers as
# its own distinct worker on the agent-bus board instead of collapsing into
# the `user@host` fallback identity (see AGENTS.md "Concurrency / isolation").
#
# Each new shell in the workspace is assigned the next unused ship name via
# `.starfleet-ai/bin/starfleetctl ship-names assign` (flock-serialized, atomic).
# Enterprise is reserved for the flagship/control session. The ship name is
# released automatically when the interactive shell exits (via EXIT trap / zsh
# zshexit hook), and also by Claude Code's SessionEnd hook.
#
# The ship name is also reflected in $PS1 (visible in the shell prompt) and in
# Claude Code's status line (via the statusLine setting in .claude/settings.json).
#
# Why this lives in a dotfile-sourced script and not a Claude Code hook:
# SessionStart/SessionEnd hooks run as one-shot child processes with no
# mechanism to export env vars back into the interactive session's own shell
# (checked against the hooks JSON schema: only systemMessage / decision /
# hookSpecificOutput.additionalContext etc — no env injection). $AGENT_ID has
# to already be in the environment *before* `claude` starts so it propagates
# via ordinary process-env inheritance into both the hook commands and every
# Bash-tool-backed shell of that session — no settings.json change needed.
#
# Usage: source this from ~/.bashrc (bash) or ~/.zshrc (zsh):
#
#   [ -f /path/to/workspace/scripts/agent-bus-auto-id.sh ] && \
#     . /path/to/workspace/scripts/agent-bus-auto-id.sh
#
# The workspace root is auto-discovered by walking up from the script's
# on-disk location looking for AGENTS.md + scripts/ (same landmarks a human
# would use). Works from any path, no hardcoded absolute paths.
#
# Deliberately does NOT overwrite an already-set $STARFLEET_SHIP_ID, so it
# composes with the run-opencode.xserver-* wrappers and run-control (which
# export their own identity before spawning the client).

# Resolve workspace root: walk up from this script's real path looking for
# AGENTS.md next to scripts/ (the same landmarks starfleetctl uses).
_mpbt_find_ws_root() {
    local dir
    dir="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/AGENTS.md" ] && [ -d "$dir/scripts" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

_MPBT_WS_ROOT="$(_mpbt_find_ws_root)" || {
    echo "agent-bus-auto-id.sh: could not locate workspace root (no AGENTS.md + scripts/ found walking up from script location)" >&2
    return 1 2>/dev/null || exit 1
}

_STARFLEETCTL_BIN="$_MPBT_WS_ROOT/.starfleet-ai/bin/starfleetctl"

# Called on first entry into the workspace when STARFLEET_SHIP_ID is unset.
_mpbt_assign_ship_name() {
    STARFLEET_SHIP_ID="$("$_STARFLEETCTL_BIN" ship-names assign 2>/dev/null)" || true
    [ -z "${STARFLEET_SHIP_ID:-}" ] && STARFLEET_SHIP_ID="ws-$$"
    export STARFLEET_SHIP_ID

    # Prefix the shell prompt with the ship name so it's always visible.
    PS1="(${STARFLEET_SHIP_ID}) ${PS1:-\$ }"
    export PS1

    # Release the reservation when this interactive shell exits.
    if [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC2064  (intentional: capture current STARFLEET_SHIP_ID value)
        trap "\"$_STARFLEETCTL_BIN ship-names\" release \"$STARFLEET_SHIP_ID\" >/dev/null 2>&1 || true" EXIT
    elif [ -n "${ZSH_VERSION:-}" ]; then
        _mpbt_ship_exit() {
            "$_STARFLEETCTL_BIN" ship-names release "$STARFLEET_SHIP_ID" >/dev/null 2>&1 || true
        }
        add-zsh-hook zshexit _mpbt_ship_exit 2>/dev/null || true
    fi
}

_mpbt_agent_id_autoassign() {
    case "$PWD" in
        "$_MPBT_WS_ROOT" | "$_MPBT_WS_ROOT"/*)
            if [ -z "${STARFLEET_SHIP_ID:-}" ]; then
                _mpbt_assign_ship_name
            else
                _mpbt_prompt_with_ship
            fi
            ;;
        *)

            ;;
    esac
}

# Always show STARFLEET_SHIP_ID in the prompt (even when inherited from parent).
_mpbt_prompt_with_ship() {
    local ship="${STARFLEET_SHIP_ID}"
    case "${PS1:-}" in
        "(${ship}) "*) ;;  # already has it
        *)
            # terminal title may be embedded before our part
            PS1="(${ship}) ${PS1:-\\$ }"
            ;;
    esac
}

if [ -n "${BASH_VERSION:-}" ]; then
    PROMPT_COMMAND="_mpbt_agent_id_autoassign${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    _mpbt_agent_id_autoassign
elif [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook chpwd _mpbt_agent_id_autoassign 2>/dev/null
    _mpbt_agent_id_autoassign
fi
