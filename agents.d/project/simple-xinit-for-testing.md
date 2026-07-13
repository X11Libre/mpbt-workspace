---
slug: project/simple-xinit-for-testing
title: "Use simple-xinit when launching a test X server + client"
order: 95
---

## Use simple-xinit when launching a test X server + client

When you need to start a separate X server (e.g. `Xvfb` or `Xephyr`) together with a
client for testing, **always use `simple-xinit`** to launch them as a pair.

### Why NOT to use `&` (background operator)

Starting the X server in the background and then launching the client does **not** work:

```bash
# WRONG — client starts before X server is ready, connection fails
Xvfb :99 &
sleep 2  # even sleep doesn't help reliably
my-client -display :99
```

The problem: there is no reliable way to know when the X server has finished initializing.
`sleep` is a race. The client will often fail with "Cannot open display" or "Connection refused".

### How to use simple-xinit

`simple-xinit` waits for the server to be ready, then exec's the client. Syntax:

```bash
simple-xinit <client-command> -- <server-command> [server-args...]
```

### Concrete examples

**Example 1: Xvfb + a test client**

```bash
SIMPLE_XINIT=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/simple-xinit
XVFB=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/Xvfb

$SIMPLE_XINIT xterm -- $XVFB :99 -screen 0 1024x768x24
```

**Example 2: Xephyr (nested X server) + client**

```bash
SIMPLE_XINIT=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/simple-xinit
XEPHYR=/home/nekrad/src/xorg/mpbt-workspace/_WORK_/xserver-master/target/bin/Xephyr

$SIMPLE_XINIT xterm -- $XEPHYR :99 -screen 1024x768
```

**Example 3: Passing environment variables to the client**

If the client needs `DISPLAY`, `XAUTHORITY`, or other env vars, wrap in a script:

```bash
cat > /tmp/run-test.sh << 'SCRIPT'
#!/bin/bash
export DISPLAY=:99
export MY_VAR=value
exec xterm
SCRIPT
chmod +x /tmp/run-test.sh

$SIMPLE_XINIT /tmp/run-test.sh -- $XVFB :99 -screen 0 1024x768x24
```

**Example 4: Running in background (detached)**

```bash
$SIMPLE_XINIT xterm -- $XVFB :99 -screen 0 1024x768x24 &
SIMPLE_PID=$!
echo "simple-xinit PID: $SIMPLE_PID"
# ... do work ...
kill $SIMPLE_PID  # cleanup
```

### Key rules

1. **NEVER use `Xvfb :N &` followed by a client** — always use `simple-xinit`
2. **The syntax is `simple-xinit CLIENT -- SERVER [ARGS...]`** — the `--` separator is mandatory
3. **Use absolute paths** for `simple-xinit`, the X server, and the client
4. **The X server binary must be the one you built** (under `_WORK_/<release>/target/bin/`), not the system one
5. **Kill the simple-xinit process** to clean up both client and server

### Path reference

For xserver-master builds:
- `simple-xinit`: `_WORK_/xserver-master/target/bin/simple-xinit`
- `Xvfb`: `_WORK_/xserver-master/target/bin/Xvfb`
- `Xephyr`: `_WORK_/xserver-master/target/bin/Xephyr`
- `Xorg`: `_WORK_/xserver-master/target/bin/Xorg`

Replace `xserver-master` with the appropriate release line (e.g. `xserver-25.2`).
