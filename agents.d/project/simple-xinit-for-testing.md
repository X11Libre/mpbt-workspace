---
slug: project/simple-xinit-for-testing
title: "Use simple-xinit when launching a test X server + client"
order: 95
---

## Use simple-xinit when launching a test X server + client

When you need to start a separate X server (e.g. `Xvfb` or `Xephyr`) together with a
client for testing, **always use `simple-xinit`** to launch them as a pair.

Starting the X server in the background (e.g. `Xvfb :N &`) and then launching the client
does **not** work reliably here: the client starts before the X server has finished
initializing, so the connection fails. `simple-xinit` waits for the server to be ready
before exec'ing the client — use it instead of the manual background-and-run pattern.

**Environment variables:** if `simple-xinit` does not pass environment variables through
to the client automatically, wrap the whole launch in a separate script and `export` the
needed variables there (e.g. `DISPLAY`, `XAUTHORITY`, and any tool-specific flags) before
calling `simple-xinit`.
