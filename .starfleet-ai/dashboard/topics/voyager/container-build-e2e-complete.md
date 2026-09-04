---
Title: Container-Build E2E komplett: os-installed + asprintf fix
Status: done
Assignee: Voyager
Created: 2026-09-04
Tags: mpbt, container, build, os-installed
---

## Zusammenfassung

Container-Build für xserver-container (Devuan daedalus) komplett erfolgreich:
**60/60 Pakete gebaut, 0 Fehler, EXIT 0.**

## Was gemacht wurde

### os-installed pkg-config-Modellierung
- 33 Pakete in `cf/xserver-master/packages/os-installed/` mit `pkg-config:` ergänzt/erstellt
- 10 bestehende Pakete um `pkg-config:` ergänzt (font-util, libdrm, libxcb-util, libxcb-wm, libxcb, libxcvt, pciaccess, x11)
- 23 neue Pakete erstellt (xfont2, fontenc, gl, egl, gbm, epoxy, xcb-glx, xcb-shape, xcb-image, xcb-icccm, xcb-keysyms, xcb-renderutil, xcb-shm, xcb-randr, xcb-xv, xcb-xkb, xkbfile, libbsd, pixman, xshmfence, libevdev, mtdev, libinput, xrandr, xinerama, spice-protocol)
- `SysPackage()` in `syspackage.go` führt `pkg-config --modversion` für jedes Paket aus (im Container, via ContainerExecutor)

### package-mapping + build-depends
- Beide Solutions (xserver-master, xserver-container): 22+ neue provides-Einträge
- `xserver.yaml`: build-depends um 22+ neue System-Dependencies erweitert
- `xf86-input-evdev.yaml`: sys/libevdev, sys/mtdev
- `xf86-input-libinput.yaml`: sys/libevdev, sys/mtdev, sys/libinput
- `xf86-input-wacom.yaml`: x11/libxrandr, x11/libxinerama
- `xf86-video-qxl.yaml`: sys/spice-protocol

### asprintf/_GNU_SOURCE-Bug
- GCC14 + `-Werror` → `implicit declaration of function 'asprintf'` in 6 Treibern
- Fix: `AC_USE_SYSTEM_EXTENSIONS` in `configure.ac` der betroffenen Treiber
- Betroffene Treiber: xf86-input-mouse, xf86-video-mach64, xf86-video-ati, xf86-video-amdgpu, xf86-video-nouveau, xf86-video-qxl
- Hinweis: Patches sind in `_WORK_/xserver-container/sources/`, NICHT im upstream repo

### Template-Symlink-Fehler erkannt
- Treiber-Pakete sind Symlinks auf `generic-driver-autotools.tmpl.yaml`
- Edits an Symlinks verändern das Common-Template für ALLE Treiber
- Korrektur: evdev, libinput, wacom, qxl als eigenständige Dateien angelegt (nicht Symlinks)

### Container-prepare
- `container.prepare` in `devuan.yaml` um alle apt-get -dev-Pakete ergänzt
- Reihenfolge: libxcvt-dev, libpciaccess-dev, libxfont-dev, libfontenc-dev, libgl1-mesa-dev, libepoxy-dev, libspice-protocol-dev, libxcb-*.dev, libxkbfile-dev, libbsd-dev, libpixman-1-dev, libxshmfence-dev, libevdev-dev, libmtdev-dev, libinput-dev, libxrandr-dev, libxinerama-dev

## Ergebnis

- **60 Tarballs** erzeugt (3rdparty: 5, xserver: 1, xts: 1, input: 10, video: 43)
- **30 pkg-config-Proben** erfolgreich (vor xserver configure)
- **Keine Build-Fehler**, keine asprintf-Fehler mehr
- Build-Exit: 0

## Offene Punkte

- asprintf-Patches in `_WORK_/xserver-container/sources/` sind Workdir-lokal, nicht upstream-committet
- Piglit-Build wird derzeit übersprungen (hattington-Treiber braucht wall有一次libdrm, der Rest braucht OpenGL-Test-Infra)
- Tarballs noch nicht nach `xserver-master` übertragen
