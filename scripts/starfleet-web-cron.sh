#!/bin/bash
# Wrapper script for starfleetctl web autostart via cron
# Loads the user's environment (bashrc/profile) to ensure API keys and PATH are available

# Load user environment
export HOME="/home/nekrad"
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
if [ -f "$HOME/.profile" ]; then
    source "$HOME/.profile"
fi

# Ensure proper PATH (from bashrc/profile)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/.bin"

# Ensure NIM_API_KEY is available for the web server daemon
if [ -z "$NIM_API_KEY" ] && [ -f "$HOME/.config/opencode/opencode.json" ]; then
    # Extract NIM_API_KEY from opencode config
    NIM_API_KEY=$(grep -o '"apiKey": "[^"]*"' "$HOME/.config/opencode/opencode.json" | head -1 | cut -d'"' -f4 | sed 's/{env://;s/}//')
    if [ -n "$NIM_API_KEY" ]; then
        export NIM_API_KEY
    fi
fi

# Workspace root
export MPBT_WORKSPACE_ROOT="/home/nekrad/src/xorg/mpbt-workspace"

# Run starfleetctl web autostart
exec "/home/nekrad/src/xorg/mpbt-workspace/.starfleet-ai/bin/starfleetctl" web autostart
