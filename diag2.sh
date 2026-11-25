#!/bin/bash

echo "=== relevante Prozesse ==="
ps -o pid,ppid,tty,stat,args -p 19372,10501

echo "=== Elternprozesse ==="
ps -o pid,ppid,tty,stat,args -p "$(ps -o ppid= -p 19372 | tr -d ' ')"
ps -o pid,ppid,tty,stat,args -p "$(ps -o ppid= -p 10501 | tr -d ' ')"

echo "=== TTYs der OpenCode-Prozesse ==="
readlink /proc/19372/fd/0 2>/dev/null
readlink /proc/10501/fd/0 2>/dev/null

echo "=== Registry-Dateien ==="
ls -la .starfleet-ai/var/comms/ships/
