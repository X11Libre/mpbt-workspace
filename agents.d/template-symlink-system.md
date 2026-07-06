---
slug: template-symlink-system
title: "Template/symlink system"
order: 80
---

## Template/symlink system

Most ~54 drivers are autotools-based and use the same build pattern.
Instead of repeating YAML 54 times:

- **Template:** `cf/_common/packages/xlibre/generic-driver-autotools.tmpl.yaml`
- **Symlinks:** each per-release driver `.yaml` is a symlink to the template
- **Special cases:** `xserver` uses meson; `elographics` and `wacom` have their own YAML
- **Regeneration:** `cf/xserver-master/packages/xlibre/update-generic.sh` creates all symlinks

Only xserver uses meson. Solution files set `meson-extra-args` per-package.
