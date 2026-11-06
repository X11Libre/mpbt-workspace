---
slug: xlibre/xorg-main-backport-exclusions
title: "xorg/main Backport — Auslassungs-Konvention"
order: 0
---

# xorg/main Backport — Auslassungs-Konvention

Versioniertes Verzeichnis der **bewusst ausgelassenen** `xorg/main`-Commits im
xorg/main-Backport-Workflow (siehe Skill `backport-xorg-main`).

Dieses File ist der dauerhafte, versionierte Anker für den Zustand "bewusst
ausgelassen" — der im Branch-Modell keine eigene Spur hat. Es lebt im
Workspace-Repo (`sop.d/`), nicht in einem Clone und nicht im Incubator, damit
Rebase/Force-Push es nicht zerstören.

## Regeln

- **Nur auslassen, wenn ein konkretes Kriterium zutrifft.** Bei jedem Lauf
  **einzeln gegenprüfen** statt die Liste zu übernehmen — ein Commit kann durch
  inzwischen gemergte Zwischenschritte anwendbar geworden sein.
- Jede Auslassung mit **SHA + Subject + Kriterium** eintragen. Begründung nur
  kurz, wenn nicht offensichtlich.
- Ausgelassene Commits werden **nicht** in den Incubator aufgenommen — sie gelten
  aber als **bearbeitet**, und der Tracker wandert über sie hinweg. Ausgelassen
  heißt entschieden, nicht offen.
- Der Tracker wird nur **nicht** über einen Commit gezogen, der **weder übernommen
  noch ausgelassen** wurde — also über echte Lücken. Ein Commit, der ausschließlich
  einen Auslassungsfall betrifft (nur `hw/xwayland/`, ein einzelner Commit mit
  dokumentiertem Grund), ist keine Lücke. Zum Prüfen:
  `git show --name-only <sha>` — betrifft die Dateiliste ausschließlich den
  Auslassungsfall, ist es eine Auslassung; sonst ist es eine Lücke und bleibt offen.
- Wird ein zuvor ausgelassener Commit doch übernommen (Kriterium entfällt),
  aus der Liste streichen — die Liste ist der Soll-Zustand, nicht ein Log.

## Auslass-Kriterien (Stand 2026-09-28)

| Kürzel | Kriterium | Begründung |
|---|---|---|
| **XWL** | `xwayland` | Bewusst im Baum entfernt (nur `hw/xwayland/` berührt) |
| **TEST** | Python-Test-Skripte (`test/*.py`, pyxtest) | Release-spezifisch; `test/pyxtest` existiert auch auf release/25.2 — nicht pauschal abwesend |
| **DUP** | Inhaltlich durch eigenen gemergten master-PR abgedeckt | `git cherry` zeigt Patch-Äquivalenz, nicht inhaltliche Enthaltenheit |
| **WIP** | Bewusst auf einem WIP-Branch für später sichern | Inhalt erledigt, aber nicht im Incubator (Voraussetzung fehlt). Als bearbeitet zählen, nie als Lücke. |
| **GHC** | GitHub-CI-Konfiguration (`.gitlab-ci/`, `.gitlab-ci.yml`) | Nur Commits auslassen, die **ausschließlich** `.gitlab-ci*` betreffen. Nicht-CI-Teil trotzdem übernehmen. |
| **N-A** | Voraussetzungs-/Zielcode fehlt im Zielbaum | `git grep` nach Symbol **im Zielzweig** (`origin/<ziel>`), nicht auf master. Im Zweifel: parken und melden. |

## Ausgelassene Commits

*Stand 2026-09-28, master-Tracker auf `b125b19fc2` (Intervall leer).*

**Bilanz des 33er-Intervalls: alle Commits bearbeitet, keine Lücke.**
- Im Incubator übernommen: 20
- Bewusst ausgelassen: 11 (XWL: 6, DUP: 5)
- Auf WIP-Branch für später: 1 (`bd3ca7da06` → `wip/fallthrough`)
- Summe: 32 (plus `ecb6644fdd`/`bbe30db5c0` bereits in DUP enthalten)

Kein Commit des Intervalls ist offen.

### Master-Ausschlüsse

| SHA | Subject | Kriterium | Kurze Begründung |
|---|---|---|---|
| `b125b19fc2` | xwayland: clean up glamor EGL state on fatal exits | XWL | xwayland entfernt |
| `1d815d00fe` | xwayland: Update RR modes only if valid | XWL | xwayland entfernt |
| `037774c7c0` | xwayland: Do not fail if cannot add the native or logical mode | XWL | xwayland entfernt |
| `ea297c9f22` | xwayland: Skip optional RR modes if CVT generation fails | XWL | xwayland entfernt |
| `79774d241a` | xwayland: Handle libxcvt_gen_mode_info() failure | XWL | xwayland entfernt |
| `4371d6d0ee` | xwayland: Skip xwl_cursor_warped_to() without an xwl_seat | XWL | xwayland entfernt |
| `316321933a` | glamor: free the link log on shader link failure | DUP | PR 3750 (`482f7b326d`) abgedeckt. Unser Fix strenger (`calloc` vs `malloc`). |
| `ecb6644fdd` | xf86: bump ABI_VIDEODRV_VERSION to 28.0 | DUP | Unser master bereits auf `SET_ABI_VERSION(28,0)` + 28.1. |
| `bbe30db5c0` | xf86: bump ABI_EXTENSION_VERSION to 11.0 | DUP | Unser master bereits auf `SET_ABI_VERSION(11,0)`. |
| `3660f54fbd` | kdrive/ephyr: dummy refresh rate through RandR | DUP | Unser master-Commit `df6b0e97a7` (gleiches Subject). |
| `3c62ee0c78` | modesetting: Fix use-after-free when aborting queued events | DUP | Nur für master gemessen. Auf 25.0 durch PR #3867 (`2959d69753`). |
| `14981eea44` | Xnest: do not reset pScreen->devPrivate to NULL | DUP | Leer-Pick: Zeile existiert bei uns bereits nicht. |
| `b9f65a275d` | ci: Run ruff check against the whole tree | GHC | Nur `.gitlab-ci.yml`, existiert bei uns nicht. |

### Weitere Ausschlüsse (DUP / N-A)

| SHA | Subject | Kriterium | Kurze Begründung |
|---|---|---|---|
| `9d068f0efb` | meson: option to disable tests | DUP | `option('tests')` + `and build_xserver` bereits auf master. |
| `d307f3b4ec` | glx: option to disable DRI glx backends | DUP | `option('glx_dri')` bereits auf master. |
| `5dc9efd5a1` | randr: PrependMode size/offset | DUP | `new_value.size = total_len` bereits auf 25.2. |
| `d509580d02` | Xi: bound SwapLongs of resolution values | DUP | Bound bereits auf 25.2 vor `SwapLongs`. |
| `bdb14dce4b` | xkb: Guard XkbAdjustGroup() | DUP | Bereits auf `release/25.2`. |
| `8e11715024` | xkb: Default to one group | DUP | Bereits auf `release/25.2`. |
| `aa0bc93d27` | xkb: Never recompute group count down to zero | DUP | Bereits auf `release/25.2`. |
| `0c764d98ee` | xkb: Keep group counts in range | DUP | Bereits auf `release/25.2`. |
| `8033c4d93e` | Xi: byte-swap XIQueryDevice ScrollClass flags | DUP | Bereits auf `release/25.2`. |
| `e19e86c29f` | modesetting: save cursor in master's sprite_priv | DUP | `msGetSpritePriv()` bereits als Funktion auf 25.2. |
| `d307f3b4ec` | glx: Allow disabling DRI glx backends | DUP | Option bereits auf `release/25.2`. |
| `b522485155` | glamor/glamor_egl: GBM fallback path | DUP | Fallback-Branch bereits auf `release/25.2`. |
| `4ef1b4cd26` | RegionValidate: Fix double free | DUP | Fix bereits auf 25.2 in `dix/region.c:1318`. |
| `da72833185` | damage: Unlink a damage from correct list | DUP | Fix #3813 bereits gemergt. |
| `cf91b97d6c` | Xi: byte-swap DeviceChanged valuator/scroll | DUP | Bereits auf 25.2 in `SDeviceChangedEvent()`. |
| `dc8e08825a` | meson: only install dri3.h if building dri3 support | N-A | `hdrs_dri3` = 0 Treffer auf 25.2. Auf 25.0 anwendbar — nicht auslassen. |
| `84908e8db5` | Fix fragile check for when to build glamor_egl | DUP | Bereits auf `if build_glamor` auf master. Auf 25.0 anwendbar. |
| `5422247702` | Fix incorrect uses of GLAMOR_HAS_GBM | N-A | Auf 25.2: 0 Treffer in modesetting. Auf 25.0: aufgenommen (`a807055d24`). |
| `309e4d35d8` | modesetting: Restrict hw cursor size | N-A | Auf master/25.2: 0 Treffer `min_cursor_width`. Auf 25.0: existiert — Feature, nicht auslassen. |

### Ausnahmen (nicht ausgelassen)

| SHA | Subject | Begründung |
|---|---|---|
| `bd3ca7da06` | Use _X_FALLTHROUGH macro | Übertragen auf `wip/fallthrough` (Tip `2b88bbc487`), nicht cherry-pick-bar. |
| `efcfd8acc7` | Xi gesture sprite traces | Ursprünglich NEIN, aber Commit-Body ist CVE-2026-93536 / ZDI-CAN-32753 (UAF in `WindowGone`) — Security-Fix, auf 25.0 aufgenommen (`e55bcbe224`). |

## Weggeworfene CI-Dateien sind ein Frühwarnsystem

`.gitlab-ci/*` wegzulassen ist kein Informationsverlust, solange man bewusst
wegschaut — es ist eine verpasste Warnung. Beispiel:
`xorg/main:.gitlab-ci/debian-install.sh:139` sagt
„xserver requires xorgproto >= 2025.1 for `_X_FALLTHROUGH`" — genau die Anforderung,
an der `wip/fallthrough` hängenbleibt.

**Faustregel:** bei jeder Auslassung von `.gitlab-ci/*` den CI-Inhalt auf
Abhängigkeitsanforderungen prüfen. Braucht der übernommene Code eine solche Anforderung,
dann als **eigene offene CI-Aufabe** festhalten, nicht in der Auslassungszeile verstecken.

## Offene CI-Aufgaben (aus ausgelassenen CI-Dateien)

| Quelle | Abhängigkeitsanforderung | Status |
|---|---|---|
| `xorg/main:.gitlab-ci/debian-install.sh:139` | `xorgproto >= 2025.1` für `_X_FALLTHROUGH` | Offen, entschärft. `wip/fallthrough` baut mit privatem Fallback-Makro grün. Rücknahme sobald xorgproto >= 2025.1 verfügbar. |
| `xorg/main:.gitlab-ci.yml` (`b9f65a275d`) | `ruff`-Durchsetzung in GitHub-CI | Offen. Unsere `.github/workflows` enthalten kein `ruff`. |

## Gegenprüfungshinweis (DUP-Kriterium)

`git cherry` meldet `316321933a` als fehlend, weil unser Fix ein eigener Patch
ist. **Patch-äquivalent ist nicht inhaltliche Enthaltenheit.** Vor dem Einreichen
eines "gleiche Funktion"-Commits prüfen, ob unser master den gleichen Codepfad
bereits behebt.

## Bauregel auf Release-Zweigen (ab 2026-09-28)

Build wie die CI: `-Dwerror=true`, nicht `-Dwerror=false`. Die alte Empfehlung
`-Dwerror=false` (wegen `os/Xtranssock.c:631`) hat genau den Mechanismus
abgeschaltet, mit dem die CI toten Code findet. Erlaubte Ausnahme: genau ein Eintrag,
`os/Xtranssock.c:631 -Werror=format-truncation` (vorbestehend, kein Backport).

## Eigene Dokumentation ist Hypothese, nicht Evidenz

Eine Anweisung, die wir selbst geschrieben haben, ist keine Evidenz, sie ist eine
Hypothese. Gegen eine Messung halten, nie übernehmen.

## Lauf 2026-10-08 — Ziel `release/25.0` (XL-0)

Intervall `867976ba87..ad26c26bf7` = **72 Commits**, davon **24 aufgenommen**
(Inkubator `rfc/backport-25.0` = `9078c564a0`), **48 ausgelassen**.
Tracker `tracking/xorg/main-on-25.0` = `ad26c26bf7`. Build `-Dwerror=true` grün.
24/24 `Signed-off-by` = Original-Autor, 24/24 `Part-of`, 24/24 `(cherry picked from ...)`.

Neu entschieden:
- `306071c0b9` — NEIN (Warnungs-Hygiene, kein Bugfix, keine `-Wextra` in unseren Lanes)
- `495ea74203` — NEIN (Test-Churn auf Release, eigene Master-#3777 nicht dupliziert)
- `cfbc5224a6` — NEIN (Entfernung/Refactoring, nur hw/xquartz, kein Bugfix)

Zusätzlich für 25.0 als DUP gemessen:
`d509580d02`, `cf91b97d6c`, `8033c4d93e`, `4ef1b4cd26`, `da72833185`,
`9d068f0efb`, `5dc9efd5a1`, `bdb14dce4b`/`8e11715024`/`aa0bc93d27`/`0c764d98ee`,
`e19e86c29f`, `14981eea44`, `316321933a`, `ecb6644fdd`/`bbe30db5c0`.

Nebenjobs-Grenze: `3c62ee0c78` = DUP über PR #3867 (offen), `495ea74203` liegt
im eigenen Task #3777 — der xorg-Lauf entscheidet über beide nicht.

## Lauf 2026-10-09 — Ziel `master` (Defiant, Praetor-Freigabe Option b)

Intervall `b125b19fc2..ad26c26bf7` = **39 Commits**. xorg/main = `ad26c26bf7`.
Tracker `tracking/xorg/main-on-master` stand auf `b125b19fc2` (39 Rückstand).
Inkubator `rfc/backport-master` **lokal aufgebaut, NICHT gepusht** (Freigabe ausstehend).

**Aufgenommen (22):** `f37bd8de26`, `cd79f876b1`, `cd083d9659`, `2b9ce9f6c6`,
`0d1b1b0bad`, `b941a473e0`, `89101a6c66`, `cea71d0273`, `2abe4632d7`, `1b6955c310`,
`ad26c26bf7`, `7a0b3e2197`, `bad7edcab0`, `6a4fb12019`, `37a1847a60`, `be57263415`,
`1f42cc1f00`, `efcfd8acc7` (alle Security/Bugfix), ruff-Block `6aa23cf642`,
`2c53e65004`, `eb9292efdb` (nur `hw/xwin/glx/gen_gl_wrappers.py`; `.gitlab-ci*`-Teile
verworfen), `f8af92cac4` (fdi2iclass.py entfernt; `COPYING` = ours, Lizenzliste divergiert).

**Ausgelassen (17):** `b9f65a275d` (GHC), `9d068f0efb` (DUP), `d307f3b4ec` (DUP),
`5dc9efd5a1` (DUP), `b522485155` (DUP), `84908e8db5` (DUP), `a66b0286b3` (DUP),
`41b3d993ba` (DUP), `5422247702` (N-A), `309e4d35d8` (N-A), `350ef434af` (N-A),
`5b22bb635b` (N-A), `a0eec5417c` (N-A), `61e546b113` (N-A), `797221a3a9` (N-A),
`1fcee9582d` (N-A), `effe0ba3cd` (N-A).

**Konsequenz:** Tracker `tracking/xorg/main-on-master` kann auf `ad26c26bf7`
gezogen werden (alle 39 bearbeitet). **Push von `rfc/backport-master` und Tracker
erst nach expliziter Praetor-Freigabe** (Option b: kein Push ohne Freigabe).
