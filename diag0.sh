#!/bin/bash

echo "=== registry ==="
.starfleet-ai/bin/starfleetctl ship-names list

echo "=== reservation files ==="
find .starfleet-ai/var/comms/ships -maxdepth 1 -type f \
    ! -name '.assign.lock' -print -exec cat {} \;

echo "=== status files ==="
find .starfleet-ai/var/comms/status -maxdepth 1 -type f -print

echo "=== relevant processes ==="
ps -eo pid,ppid,tty,stat,args | grep -E '[s]tarfleetctl run|[o]pencode'
