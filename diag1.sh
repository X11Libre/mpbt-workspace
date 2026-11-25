#!/bin/bash

echo "=== Defiant process ==="
tr '\0' ' ' </proc/10338/cmdline; echo
tr '\0' '\n' </proc/10338/environ | grep -E '^(STARFLEET_|OPENCODE_)'
readlink /proc/10338/fd/0

echo "=== status records ==="
cat .starfleet-ai/var/comms/status/Defiant.json
cat .starfleet-ai/var/comms/status/Enterprise.json
