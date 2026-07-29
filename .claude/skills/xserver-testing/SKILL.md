---
name: xserver-testing
description: "Start X server + client for testing using simple-xinit. Use when asked to test X server, run Xephyr/Xvfb, launch a display, or verify a build."
---

# xserver-testing

## When to use

Use this skill when you need to:
- Test an X server build (Xvfb, Xephyr, Xorg)
- Launch a display for client testing
- Verify a build works by running a client against it
- Any task that requires starting an X server together with a client

## NEVER do this

```bash
# WRONG — race condition, client fails
Xvfb :99 &
xterm -display :99
```

```bash
# ALSO WRONG — sleep doesn't guarantee server is ready
Xvfb :99 &
sleep 3
xterm -display :99
```

## ALWAYS do this

```bash
SIMPLE_XINIT=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/simple-xinit
XVFB=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/Xvfb

$SIMPLE_XINIT xterm -- $XVFB :99 -screen 0 1024x768x24
```

## Syntax

```
simple-xinit <client-command> -- <server-command> [server-args...]
```

The `--` separator is **mandatory**. It separates the client from the server.

## Step-by-step procedure

### 1. Find the binaries

```bash
RELEASE=xserver-master  # or xserver-25.2, xserver-25.1, xserver-25.0
BASE=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/$RELEASE/target/bin

SIMPLE_XINIT=$BASE/simple-xinit
XVFB=$BASE/Xvfb
XEPHYR=$BASE/Xephyr
```

Verify they exist:
```bash
ls -la $SIMPLE_XINIT $XVFB
```

### 2. Pick a display number

Check which displays are in use:
```bash
ls /tmp/.X11-unix/
```

Pick an unused number (e.g. `:99`).

### 3. Launch with simple-xinit

**Simple case** (client that doesn't need env vars):
```bash
$SIMPLE_XINIT xterm -- $XVFB :99 -screen 0 1024x768x24
```

**Client needs env vars** (wrap in a script):
```bash
cat > /tmp/run-client.sh << 'EOF'
#!/bin/bash
export DISPLAY=:99
export SOME_VAR=value
exec xterm
EOF
chmod +x /tmp/run-client.sh

$SIMPLE_XINIT /tmp/run-client.sh -- $XVFB :99 -screen 0 1024x768x24
```

**Run in background** (for automated testing):
```bash
$SIMPLE_XINIT xterm -- $XVFB :99 -screen 0 1024x768x24 &
SIMPLE_PID=$!
echo "Started simple-xinit PID: $SIMPLE_PID"

# ... run your tests ...

# Cleanup
kill $SIMPLE_PID
```

### 4. Verify it's running

```bash
# Check processes
ps aux | grep -E "simple-xinit|Xvfb|xterm"

# Check display
ls /tmp/.X11-unix/

# Test connection
DISPLAY=:99 xdpyinfo | head -5
```

### 5. Cleanup

```bash
kill $SIMPLE_PID  # kills both client and server
# or
pkill -f "simple-xinit :99"
```

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|-------------|-----|
| `Xvfb :99 &` then `client` | Race: client starts before server | Use `simple-xinit` |
| `sleep 5` after backgrounding | Not reliable, still a race | Use `simple-xinit` |
| Missing `--` separator | `simple-xinit` can't parse args | Add `--` between client and server |
| Using system Xvfb | May not match your build | Use `_WORK_/<release>/target/bin/Xvfb` |
| Forgetting to kill | Zombie processes accumulate | Always `kill $SIMPLE_PID` when done |

## Environment variables

`simple-xinit` does NOT automatically pass environment variables to the client. If your client needs specific env vars (like `DISPLAY`, `XAUTHORITY`, tool-specific flags), you MUST wrap the client in a shell script that exports them.

## Reference

See also: `agents.d/xlibre/simple-xinit-for-testing.md` in the workspace.
