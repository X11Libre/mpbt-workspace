---
title: "Local workflow rules"
category: local
---

# workflow rules

IMPORTANT RULES !

* ships need to coordinate with each other when working in the same source repo (especially on starfleetctl source)
* make safety checks before starting to change files (exception: local workspace files, which are generally safe)
* when you're commanded to wait for somebody else (ship or praetor), DO NOT mix up the auto-restart messages with the signal to stop waiting
* NOTE: opencode plugin automatically injects a message and starts new turn when there was a transient API error
* that only means you should retry what you've been doing when the turn was interrupted, but NOT stop an explicit wait (eg. somebody told you to wait until he's finished)
* if a ships is getting several tasks assigned, those should be done one by one - completely finish one before starting the next
