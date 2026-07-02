#!/usr/bin/env bash
#
# agent-bus-auto-id.sh — auto-assign a unique, session-stable $AGENT_ID
# whenever an interactive shell is sitting inside this workspace tree, so a
# plain `claude` (or opencode, or anything else) launched here registers as
# its own distinct worker on the agent-bus board instead of collapsing into
# the `user@host` fallback identity (see AGENTS.md "Concurrency / isolation",
# the "Caveat: the Claude Code hook inherits the session's env..." paragraph).
#
# Why this lives in a dotfile-sourced script and not a Claude Code hook:
# SessionStart/SessionEnd hooks run as one-shot child processes with no
# mechanism to export env vars back into the interactive session's own shell
# (checked against the hooks JSON schema: only systemMessage / decision /
# hookSpecificOutput.additionalContext etc — no env injection). $AGENT_ID has
# to already be in the environment *before* `claude` starts, so it propagates
# via ordinary process-env inheritance into both the SessionStart/SessionEnd
# hook commands (which already do `agent-bus status`/`clear`) and every
# Bash-tool-backed shell of that session — no settings.json change needed,
# the existing hooks just work once this env var is populated.
#
# Usage: source this from ~/.bashrc (bash) or ~/.zshrc (zsh):
#
#   [ -f /home/nekrad/src/xorg/mpbt-workspace/scripts/agent-bus-auto-id.sh ] && \
#     . /home/nekrad/src/xorg/mpbt-workspace/scripts/agent-bus-auto-id.sh
#
# Deliberately does NOT overwrite an already-set $AGENT_ID, so it composes
# with the run-opencode.xserver-* wrappers (which export their own
# release-based AGENT_ID) and with a manually-exported one.

_MPBT_WS_ROOT="/home/nekrad/src/xorg/mpbt-workspace"

_mpbt_agent_id_autoassign() {
    case "$PWD" in
        "$_MPBT_WS_ROOT" | "$_MPBT_WS_ROOT"/*)
            if [ -z "$AGENT_ID" ]; then
                export AGENT_ID="ws-$$"
            fi
            ;;
    esac
}

if [ -n "$BASH_VERSION" ]; then
    PROMPT_COMMAND="_mpbt_agent_id_autoassign${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
elif [ -n "$ZSH_VERSION" ]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook chpwd _mpbt_agent_id_autoassign 2>/dev/null
    _mpbt_agent_id_autoassign
fi
