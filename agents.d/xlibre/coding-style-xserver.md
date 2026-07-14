---
slug: xlibre/coding-style-xserver
title: "Xserver source code: coding style"
order: 190
---

# Coding guidelines for xserver source

## When to use

* applies only for new code - don't change existing code
* also for code blocks that are already replaced by some commit for other reaons
* also when explicitly instructed to do a styling cleanup

## Formatting rules

* always use braced bodies on `if`/`while`/`for`/`else` (starting brace at same line, eg `if (...) {`)
* use stdbool's `bool` instead of Xlib's `Bool`
* indent with 4 spaces instead of tab
* on `#else` and `#endif` add the original `#if(def)` expression as comment, if the whole block spans more than 50 lines or several nested conditionals

## Function declarations

* no newline between result type, attributes (eg `_X_EXPORT`) and funtion name
* all (non-static) functions should be documented (doxygen-@-style) within the header
* static functions shall be documented at their declaration/implementation
* no `extern` on function prototypes, only needed on variables

## Include order

* 1st block: compile config files (eg. `<dix-config.h>`)
* 2nd block: system includes (libc, xlib, ...)
* 3rd block: xserver includes (with path, eg. `dix/dix_priv.h`
* 4th block: local directory includes
* keep one newline between blocks (and last block and start of actual code)

## exporting

* only symbols supposed to be used by drivers / modules shall be `_X_EXPORT`'ed.
* if symbol is needed by external drivers, shall be declared in public SDK header (./include/*.h)
* if it's needed only by internal modules or drivers (eg. `modesetting` or `glx`), inside a private header (`*_priv.h`), but still X_EXPORT'ed.
* document who really needs it

## Misc

* new files should contain a SPDX-License-Identifier as well author name/email / copyright
* header guards shall be named _XLIBRE_XSERVER_<simplified-header-slug>
