#!/usr/bin/env bash
#
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# agent-bus-auto-id.sh — auto-assign a Star Trek ship name as $AGENT_ID
# whenever an interactive shell is sitting inside this workspace tree, so a
# plain `claude` (or opencode, or anything else) launched here registers as
# its own distinct worker on the agent-bus board instead of collapsing into
# the `user@host` fallback identity (see AGENTS.md "Concurrency / isolation").
#
# Each new shell in the workspace is assigned the next unused ship name from
# scripts/ship-names.txt via scripts/ship-names (flock-serialized, atomic).
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
#   [ -f /home/nekrad/src/xorg/mpbt-workspace/scripts/agent-bus-auto-id.sh ] && \
#     . /home/nekrad/src/xorg/mpbt-workspace/scripts/agent-bus-auto-id.sh
#
# Deliberately does NOT overwrite an already-set $AGENT_ID, so it composes
# with the run-opencode.xserver-* wrappers and run-control (which export their
# own identity before spawning the client).

_MPBT_WS_ROOT="/home/nekrad/src/xorg/mpbt-workspace"

# Called on first entry into the workspace when AGENT_ID is unset.
_mpbt_assign_ship_name() {
    AGENT_ID="$("$_MPBT_WS_ROOT/scripts/ship-names" assign 2>/dev/null)" || true
    [ -z "${AGENT_ID:-}" ] && AGENT_ID="ws-$$"
    export AGENT_ID

    # Prefix the shell prompt with the ship name so it's always visible.
    PS1="(${AGENT_ID}) ${PS1:-\$ }"
    export PS1

    # Release the reservation when this interactive shell exits.
    if [ -n "${BASH_VERSION:-}" ]; then
        # shellcheck disable=SC2064  (intentional: capture current AGENT_ID value)
        trap "\"$_MPBT_WS_ROOT/scripts/ship-names\" release \"$AGENT_ID\" >/dev/null 2>&1 || true" EXIT
    elif [ -n "${ZSH_VERSION:-}" ]; then
        _mpbt_ship_exit() {
            "$_MPBT_WS_ROOT/scripts/ship-names" release "$AGENT_ID" >/dev/null 2>&1 || true
        }
        add-zsh-hook zshexit _mpbt_ship_exit 2>/dev/null || true
    fi
}

_mpbt_agent_id_autoassign() {
    case "$PWD" in
        "$_MPBT_WS_ROOT" | "$_MPBT_WS_ROOT"/*)
            if [ -z "${AGENT_ID:-}" ]; then
                _mpbt_assign_ship_name
            else
                _mpbt_prompt_with_ship
            fi
            ;;
        *)

            ;;
    esac
}

# Always show AGENT_ID in the prompt (even when inherited from parent).
_mpbt_prompt_with_ship() {
    local ship="${AGENT_ID}"
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
elif [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook chpwd _mpbt_agent_id_autoassign 2>/dev/null
    _mpbt_agent_id_autoassign
fi
