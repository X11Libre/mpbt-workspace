---
Title: "Nachhalten: #3793-Backports (#3813/#3814/#3811) bis alle drei gemergt sind — Use-after-free in der Damage-Liste"
Category: active
Kind: task
Status: open
Assigned-To: "Enterprise"
Created-By: "Enterprise"
Created: 2026-10-02T00:00:00Z
Doc-Ref: "—"
---

**Nachhalt-Topic.** Angelegt auf ausdrücklichen Wunsch des Maintainers am
2026-10-02, weil #3781 geschlossen wurde und damit **nichts** mehr im Board auf die
offenen Backports zeigte. Dieses Topic ist der einzige Ort, an dem sie noch hängen.

## Warum das wichtig ist

#3781 ist als **superseded** geschlossen — zu Recht, der Fix steckt in #3793
(merged 2026-10-02 als `ccfc4797cfc4`). Damit war der **einzige** Verweis auf die
Release-Linien mitgelöscht: der Bug ist ein **Use-after-free in der Damage-Liste**,
client-erreichbar, ausgelöst durch einen Wechsel des Window-Pixmaps
(Composite-Redirect, rootless, Present-Flip). Auf den Release-Zweigen steht die
**ältere, ungeschützte Form** — `pListHead` existiert dort nachweislich auf keinem
Zweig (`git grep -c pListHead origin/release/25.x` → 0).

**Bis alle drei gemergt sind, tragen 25.0/25.1/25.2 den Fehler.**

## Stand 2026-10-02

| Branch | PR | Commit | Inhalt | Status |
|---|---|---|---|---|
| release/25.2 | [#3813](https://github.com/X11Libre/xserver/pull/3813) | `88760f31d9` | `include/damagestr.h` + `miext/damage/damage.c` | **offen** |
| release/25.1 | [#3814](https://github.com/X11Libre/xserver/pull/3814) | `04954197c2` | `miext/damage/damagestr.h` + `miext/damage/damage.c` | **offen** |
| release/25.0 | [#3811](https://github.com/X11Libre/xserver/pull/3811) | — | `miext/damage/damagestr.h` + `miext/damage/damage.c` | **offen**, Diff wird von Interpid auf das Nötige gekürzt |

Zusätzlich zu prüfen: #3811 enthielt ursprünglich ~30 Zeilen Master-Churn
(`stdbool.h`, `include/mipict.h`, `__FUNCTION__` → `__func__`, `Bool` → `bool`,
`min/max` → `MIN/MAX`). Barcleys Gegenprobe am ungepatchten Tip zeigte, dass die
beiden gefährlichen Löschungen korrekt drin sind — aber Refactoring-Churn gehört laut
`backport-ours` nicht auf einen Release-Zweig, weil sonst im Fehlerfall nicht mehr
unterscheidbar ist, ob der Fix oder der Churn nicht gebaut hat.

## Checkliste — abhaken, sobald gemergt

- [ ] #3813 (release/25.2) gemergt
- [ ] #3814 (release/25.1) gemergt
- [ ] #3811 (release/25.0) gemergt **und** Diff auf Fixanteil reduziert

## Verifikation je Zweig, die ich jeweils selbst messe

    gh pr view <pr> --repo X11Libre/xserver --json state -q .state
    git -C _WORK_/xserver-master/sources/xlibre/xserver grep -c pListDrawable origin/release/<rel> -- miext/damage/damage.c
    # bzw. auf 25.2:  include/damagestr.h

Erwartung nach dem Merge: `pListDrawable` existiert im Zweig, `pListHead` **nicht** mehr,
und der Fehlerpfad in `damageSetWindowPixmap()` nutzt `pListDrawable`.

## Merge

release/* wird **nie** automatisch gemergt. Merge macht der Maintainer. Ein
`bot-review-passed` und grüne CI autorisieren keinen Release-Merge.

## Abgeschlossene Geschwister (nicht mehr nachhalten)

- **#3776** → #3801/#3802/#3803 — **alle drei gemergt**
- **#3779** → #3799/#3805 gemergt; **#3794** (25.2) noch offen, hatte 28 `cancelled`
- **#3777** → #3797/#3798/#3800 offen; die roten Lanes auf 25.0/25.1 sind der
  locale-abhängige Assert, den der Backport erst sichtbar macht
- **xkb-Serie** #3783-3786 → #3807/#3809/#3810 (Guard) und #3808/#3795/#3796
  (Serie) — **alle sechs gemergt**
