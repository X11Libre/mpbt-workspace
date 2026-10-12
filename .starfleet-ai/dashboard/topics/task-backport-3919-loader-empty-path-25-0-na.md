Title: "N-A: Backport #3919 (loader empty module path) auf release/25.0"
Category: active
Kind: task
Status: "open"
Created-By: "XL-0"
Created: "2026-10-12T12:45:30Z"
Assigned-To: "—"
Doc-Ref: "—"
Slug: task-backport-3919-loader-empty-path-25-0-na

Praetor-Backport #3919 (xfree86 loader: empty module path as not present) fuer release/25.0.

Befund: N-A (nicht anwendbar), KEIN PR geoeffnet.

Messung an origin/release/25.0 (frisch gefetcht):
- LoaderSetPath(const char *path) = EIN Argument (loaderProcs.h:76, loadmod.c:167).
- Fehlerstring 'Failed to store module search path': 0 Treffer auf 25.0 (25.1/25.2 je 1x).
- Zwei-Arg-Feature (driver,path) aus 9f25f5d3f1 'xfree86: make search paths configurable for certain modules' — auf master/25.1/25.2 vorhanden, auf 25.0 NICHT.
- Caller auf 25.0: xf86Init.c:333 LoaderSetPath(xf86ModulePath); xf86platformBus.c:333 LoaderSetPath(path) mit path='modulepath,xf86ModulePath' (nie leer).

=> Voraussetzung/Zielcode fehlt; Bug kann auf 25.0 nicht auftreten. 25.1/25.2 vulnerable (XL-1/XL-2).
