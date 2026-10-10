---
slug: xlibre/xorg-main-backport-exclusions
title: "xorg/main Backport — Auslassungs-Konvention"
order: 0
---

# xorg/main Backport — Auslassungs-Konvention

Versioniertes Verzeichnis der **bewusst ausgelassenen** `xorg/main`-Commits im
xorg/main-Backport-Workflow (siehe Skill `backport-xorg-main`).

Dieses File ist der dauerhafte, versionierte Anker für den Zustand "bewusst
ausgelassen" — der im Branch-Modell keine eigene Spur hat (gemergt faellt via
Rebase aus der Queue, offener PR trägt `[PR #NNNN]`, Auslassung ist sonst
unsichtbar). Es lebt im Workspace-Repo (`sop.d/`), nicht in einem Clone und
nicht im Incubator, damit Rebase/Force-Push es nicht zerstören.

## Regeln

- **Nur auslassen, wenn ein konkretes Kriterium zutrifft** (unten). Bei jedem
  Lauf **einzeln gegenprüfen** statt die Liste zu übernehmen — ein Commit kann
  durch inzwischen gemergte Zwischenschritte anwendbar geworden sein.
- Jede Auslassung mit **SHA + Subject + Begründung** eintragen.
- Ausgelassene Commits werden **nicht** in den Incubator aufgenommen — sie gelten
  aber als **bearbeitet**, und der Tracker wandert über sie hinweg. Ausgelassen
  heißt entschieden, nicht offen.
- Der Tracker wird nur **nicht** über einen Commit gezogen, der **weder übernommen
  noch ausgelassen** wurde — also über echte Lücken. Ein Commits, der ausschließlich
  einen Auslassungsfall betrifft (nur `hw/xwayland/`, ein einzelner Commit mit
  dokumentiertem Grund), ist keine Lücke. Zum Prüfen:
  `git show --name-only <sha>` — betrifft die Dateiliste ausschließlich den
  Auslassungsfall, ist es eine Auslassung; sonst ist es eine Lücke und bleibt offen.
  Am 2026-09-28 galt das für alle 12 Auslassungen des master-Intervalls, deshalb
  konnte der Tracker auf `b125b19fc2` gezogen werden und das Intervall ist leer.
- Wird ein zuvor ausgelassener Commit doch übernommen (Kriterium entfällt),
  aus der Liste streichen — die Liste ist der Soll-Zustand, nicht ein Log.

## Auslass-Kriterien (Stand 2026-09-28)

| Kürzel | Kriterium | Begründung |
|---|---|---|
| **XWL** | `xwayland` | Bewusst im Baum entfernt (nur hw/xwayland/ berührt) |
| **TEST** | Python-Test-Skripte (`test/*.py`, pyxtest) | Release-spezifisch: für master nicht anwenden (dort vorhanden); für Releases einzeln prüfen, denn `test/pyxtest` existiert auch auf release/25.2 und ist nicht pauschal abwesend |
| **DUP** | Inhaltlich durch eigenen gemergten master-PR abgedeckt | `git cherry` zeigt patch-Äquivalenz, nicht inhaltliche Enthaltenheit |
| **WIP** | Bewusst auf einem WIP-Branch für später sichern | Der Inhalt ist erledigt, aber **nicht** in den Incubator übernommen, weil eine Voraussetzung fehlt (Abhängigkeit, Konflikt mit eigener Entwicklung). Bearbeitet, nur woanders. **Auch als bearbeitet zählen, nie als Lücke behandeln** — die Fortsetzungsbedingung steht beim Commit und in der Zeile unten. |
| **GHC** | GitHub-CI-Konfiguration (`.gitlab-ci/`, `.gitlab-ci.yml`) | Wir haben `.gitlab-ci/` vor Langem entfernt und nutzen nur GitHub CI. **Nur Commits auslassen, die ausschließlich `.gitlab-ci*` betreffen** — CI-Änderungen kommen oft zusammen mit anderen (z. B. Dependency-Anpassung); dann wird der Nicht-CI-Teil übernommen und nur die CI-Dateien fallen weg. Entscheidend ist die **Dateimenge, nicht das Subject**; den ganzen Commit zu verwerfen ist falsch. Messgriff: `git show --name-only <sha>` — nur wenn die Liste **identisch** mit `.gitlab-ci*`-Pfaden ist, auslassen; sonst teill übernehmen. Alternativ als Resttest: `git show --name-only <sha> \| grep -vE '\.gitlab-ci/' \| grep -q .` |
| **N-A** | Voraussetzungs-/Zielcode fehlt im Zielbaum | Der Commit ändert Code, den es dort nicht gibt (andere Maschine, andere Pfad-Lage, eigene Entwicklung hat ihn abgelöst). Aufnehmen hieße, fremden Code samt toter Felder/Optionen einzubauen. Messgriff: `git grep` nach dem geänderten Symbol **im Zielzweig** (`origin/<ziel>`), nicht auf master und nicht auf den Patch schließen. Im Zweifel: parken und melden. |

## Ausgelassene Commits

*Stand 2026-09-28, master-Tracker auf `b125b19fc2` (Intervall leer), `xorg/main`
ebenfalls auf `b125b19fc2`.*

**Bilanz des 33er-Intervalls: alle Commits bearbeitet, keine Lücke.**

| Kategorie | Anzahl | Kriterien |
|---|---|---|
| im Incubator übernommen | 20 | — |
| bewusst ausgelassen | 11 | XWL (6), DUP (5) |
| auf WIP-Branch für später | 1 | WIP (`bd3ca7da06` → `wip/fallthrough`) |
| **Summe** | **32** | plus `ecb6644fdd`/`bbe30db5c0` bereits in DUP enthalten |

Die drei Kategorien sind alle **bearbeitet**: übernommen, entschieden ausgelassen
oder bewusst gesichert. Kein Commit des Intervalls ist offen.

| SHA | Subject | Kriterium | Begründung |
|---|---|---|---|
| `b125b19fc2` | xwayland: clean up glamor EGL state on fatal exits | XWL | xwayland entfernt |
| `1d815d00fe` | xwayland: Update RR modes only if valid | XWL | xwayland entfernt |
| `037774c7c0` | xwayland: Do not fail if cannot add the native or logical mode | XWL | xwayland entfernt |
| `ea297c9f22` | xwayland: Skip optional RR modes if CVT generation fails | XWL | xwayland entfernt |
| `79774d241a` | xwayland: Handle libxcvt_gen_mode_info() failure | XWL | xwayland entfernt |
| `4371d6d0ee` | xwayland: Skip xwl_cursor_warped_to() without an xwl_seat | XWL | xwayland entfernt |
| `316321933a` | glamor: free the link log on shader link failure | DUP | Inhaltlich durch gemergten PR 3750 (`482f7b326d`) abgedeckt. Upstream: `malloc` + `if(!info)` + `free`. Unser Fix: `calloc` + `if(!info)` + `ErrorF` + `free` — strenger, denn `calloc(1,0)` liefert einen validen Zeiger, `malloc(0)` nicht sicher; die Leak-Abdeckung wird an genau dieser Entartung entschieden. |
| `ecb6644fdd` | xf86: bump ABI_VIDEODRV_VERSION to 28.0 | DUP | Unser master hat bereits `SET_ABI_VERSION(28,0)` plus `CONFIG_LEGACY_NVIDIA_PADDING` mit 28.1. Der 27→28-Bump ist inhaltlich abgedeckt; cherry-pick kollidiert nur und ändert nichts. |
| `bbe30db5c0` | xf86: bump ABI_EXTENSION_VERSION to 11.0 | DUP | Unser master hat bereits `SET_ABI_VERSION(11,0)`. Der 10→11-Bump ist inhaltlich abgedeckt. |
| `3660f54fbd` | kdrive/ephyr: Report a dummy refresh rate through RandR to make proton >= 8 happy | DUP | Inhaltlich durch unseren master-Commit `df6b0e97a7` (gleiches Subject) abgedeckt; gemessen über `git log -S 'Dummy refresh rate'`, der ephyr.c enthält den Code bereits. Cherry-Pick war ein Leer-Pick ('nichts zu committen'). |
| `3c62ee0c78` | modesetting: Fix use-after-free when aborting queued events | DUP | **Nur fuer `master` gemessen** (Ursprung: eigener Master-Commit `2959d69753`, selbst Import von xorg MR 2290) — dort `if (!q->aborted && match(...))` in `ms_drm_abort` vorhanden, zusaetzlich `aborted`-Feld an 4 Stellen. **Achtung, pro Ziel neu messen:** `release/25.1` enthaelt den Guard ebenfalls, `release/25.2` und `release/25.0` **nicht** (gemessen 2026-10-08: Guard fehlt in `ms_drm_abort` in beiden). 25.2: PR #3854 (offen). 25.0: Backport offen. Ohne diese Ziel-Angabe waere die Zeile fuer 25.2/25.0 ein falscher Skip.  **UPDATE Lauf 2026-10-08, Ziel 25.0: jetzt DUP** — gedeckt durch eigenen Backport-PR **#3867** (Quelle `2959d69753`, offen gegen `release/25.0`). Damit entfaellt die fruehere Anweisung "fuer 25.0 nicht als DUP skippen" (Beauftragung m0128 war VOR PR #3867). **Falls #3867 faellt: Zeile fuer 25.0 zuruecknehmen, xorg-Commit nachholen.** |
| `14981eea44` | Xnest: do not reset pScreen->devPrivate to NULL | DUP | Leer-Pick: unser hw/xnest/Screen.c enthält die `pScreen->devPrivate = NULL`-Zeile bereits nicht (nur `dixSetPrivate(&pScreen->devPrivates, ...)`). |
| `b9f65a275d` | ci: Run ruff check against the whole tree | GHC | Lauf 2026-10-07, Intervall `b125b19fc2..ad26c26bf7`, Ziel `master`. Dateiliste gemessen: **genau eine Datei**, `.gitlab-ci.yml` — damit ist das GHC-Kriterium erfüllt (Dateimensge, nicht das Subject). CI-Inhalt: Job `ruff-check` mit `uvx ruff check`, **keine** Abhängigkeits-Installation. Der zugehörige Ruff-Block (`6aa23cf642`, `2c53e65004`, `eb9292efdb`) ist echter Quellcode und wird übernommen; die fehlende Durchsetzung steht als offene CI-Aufgabe unten. |
| `9d068f0efb` | meson.build: meson_options.txt: add build option to disable building tests | DUP | Lauf 2026-10-07, Ziel `master`. Bereits vorhanden: `meson_options.txt:128` `option('tests', …)` **und** `meson.build:847` `if (get_option('tests') and host_machine.system() != 'windows' and build_xserver)` — gebracht von unserem `6851e17816` mit gleichem Subject. Die Patch-IDs unterscheiden sich (unser Check ist strenger: zusätzlich `and build_xserver` plus Klammern), deshalb meldet `git cherry` den Commit fälschlich als fehlend — **Patch-Äquivalenz ist nicht inhaltliche Enthaltenheit**, genau der dokumentierte DUP-Fall. Aufnehmen würde `and build_xserver` entfernen (Regression: Tests auch ohne Server-Gebäude). Zusätzlich alignierter Konflikt in `meson_options.txt`: die von upstream mitgezogene `xf86-input-inputtest`-Option existiert bei uns bereits (Zeile 172), ein Take-theirs hätte sie doppelt definiert. |
| `71c7824e80` | meson: check cpu_family() instead of cpu() | DUP / ENTSCHEIDUNG | Lauf 2026-10-07. **Praetor-Entscheidung: „koennen wir getrost weglassen"** (morgige Console). Zusaetzlich gemessen: auf `master` ist der Inhalt bereits da — unsere eigene PR #3780 ist gemergt (`ca2b7f19fc`), `meson.build` führt `cpu_family()` dreimal, kein `cpu()` mehr; dort wäre es also auch DUP. Auf den **Release-Zweigen ist die Aenderung dagegen abwesend** (`release/25.2`: 0 Treffer; unsere Backports #3815/#3816/#3817 sind `CLOSED`, nicht gemergt) — dort beruht der Ausschluss **allein auf der Entscheidung**, nicht auf inhaltlicher Enthaltenheit. Bewusst so vermerkt, damit der nächste Lauf nicht „fehlt doch" meldet und jemand nachliefert.  **Ziel 25.0 (Lauf 2026-10-08): bestaetigt** — `cpu_family()` 0 Treffer dort; Skip beruht weiterhin auf der Praetor-Entscheidung, nicht auf Inhalt. |
| `309e4d35d8` | modesetting: Restrict hw cursor size optimization to known working hw | N-A | Lauf 2026-10-07, alle Ziele. Die eingeschraenkte Maschine stammt aus `1f41320e1c42` und existiert bei uns **nicht mehr**: `min_cursor_width` gemessen mit 0 Treffern auf `origin/master` **und** auf `origin/release/25.2`; unsere Cursor-Größen-Ermittlung laeuft ueber `drmmode_probe_cursor_size` + `dimensions[]` (abgeloest durch `05c63d2a02`, `e6c980f08e`). Aufnehmen wuerde die neue Option `CursorSizeOptimization` samt `allow_cursor_size_optim`-Feld einfuegen, das bei uns niemand aufruft — toter Code plus Feature. Entscheidung: N/A. Umkehr (die Einschraenkung an unsere Probe-Mechanik anpassen) waere eine Feature-Entscheidung des Praetors und gehoert in den Entscheidungs-Report, nicht in einen Lauf.  **Ziel 25.0 (Lauf 2026-10-08): N-A-Begruendung trifft dort NICHT zu** — `drmmode_probe_cursor_size` + `min_cursor_width` existieren auf 25.0 (gemessen). Skip fuer 25.0 = **NEIN** (neue Option `CursorSizeOptimization` = Feature pro Release-Regel). |
| `d307f3b4ec` | glx: include: meson_options.txt: Allow disabling DRI glx backends | DUP | Lauf 2026-10-07, Ziel `master`. **Inhaltlich vollstaendig vorhanden**, Patch-ID nur wegen Pfad-Reorg verschieden (deshalb Konflikt statt Leer-Pick). Alle 9 Teile mit den *richtigen* Pfaden geprueft: `meson_options.txt:45` `option('glx_dri', …)`; `meson.build:514-524` `dri_dep = dependency('dri', required: false)` + `glx_dri_opt` + `build_glx_dri` + `error(… dri.pc …)`; `include/meson.build:236-239` das `if build_glx_dri`-Gating mit `DRI_DRIVER_PATH`/`BUILD_GLX_DRI` (textgleich zum Upstream-Diff); `Xext/glx/meson.build:32-37` `if build_glx_dri` + `srcs_glx += 'glx_dri/…'`; `Xext/glx/glxext.c:283-287` `#ifdef BUILD_GLX_DRI`-Guard um `__glXDRISWRastProvider`; die vier `glxdri*`-Dateien liegen bereits unter `Xext/glx/glx_dri/` (unsere eigene Umbenennung). Fehlerquelle beim Gegenpruefen: Upstream-Pfade (`glx/…`) greifen bei uns ins Leere — **Pfad zuerst pruefen**, dann Inhalt.  **Ziel 25.0 (Lauf 2026-10-08): DUP trifft NICHT zu** — `option('glx_dri')` 0 Treffer dort. Skip fuer 25.0 = **NEIN** (neue Build-Option = Feature). |
| `bd3ca7da06` | Use _X_FALLTHROUGH macro to silence fallthrough warnings in clang as well | ÜBERTRAGEN | Nicht cherry-pick-bar: 12 Konfliktdateien, keine davon reine Kommentar-Konvertierung (InputClass.c nutzt `negated`, upstream `matchtype`; dix/events.c nutzt `GRAB_STATE_FROZEN_WITH_EVENT`, upstream `FROZEN_WITH_EVENT`; `.gitlab-ci*` existiert bei uns nicht). **Die Arbeit ist auf `wip/fallthrough` erledigt** (Tip 2b88bbc487): 35 Vorkommen von `/* fallthrough */`, `/* fall through */`, `/* fall-through */`, `/* FALLTHROUGH */` in 16 Dateien sind zu `_X_FALLTHROUGH; /* fallthrough */` ersetzt, plus ein privates Fallback-Makro in `include/fallthrough.h`. **Baut grün** (meson/ninja, `-Dwerror=true`, 629/629). **Das Fallback-Makro wird mit xorgproto >= 2025.1 überflüssig und ist dann zu löschen, nicht zu überschreiben** — siehe offene CI-Aufabe. |
| `d509580d02` | Xi: bound SwapLongs of resolution values to the request length | DUP | Lauf 2026-10-07, Ziel 25.2. Gemessen am Zweiginhalt statt am Patch: der Bound steht auf `release/25.2` bereits **vor** dem `SwapLongs` (`if ((len < bytes_to_int32(sizeof(xDeviceResolutionCtl))) \|\| (len != bytes_to_int32(...) + r->num_valuators))` bei `Xext/xinput/chgdctl.c:109-114` vs `SwapLongs` bei :131). Zusaetzlich existiert `SProcXChangeDeviceControl` auf 25.2 **nicht als eigene Funktion** — der Swap laeuft inline unter `client->swapped`. Die Wirkung des Fixes ist damit schon da; `git cherry` meldet ihn trotzdem als fehlend (Patch-Aequivalenz != inhaltliche Enthaltenheit). |

## Weggeworfene CI-Dateien sind ein Frühwarnsystem

Wenn `.gitlab-ci/*` ausfällt, ist das **kein Informationsverlust**, solange man bewusst
wegschaut — es ist eine verpasste Warnung. Der Upstream-CI-Block ist oft die einzige
maschinenlesbare Stelle, an der eine neue Abhängigkeitsanforderung früh steht. Beispiel
aus diesem Lauf: `xorg/main:.gitlab-ci/debian-install.sh:139` sagt
„xserver requires xorgproto >= 2025.1 for _X_FALLTHROUGH" — genau die Anforderung, an der
`wip/fallthrough` hängenbleibt. Ohne den CI-Teil fällt das erst auf, wenn der Code die
Abhängigkeit wirklich braucht, also mitten im Lauf.

**Faustregel:** bei jeder Auslassung von `.gitlab-ci/*` den CI-Inhalt auf
Abhängigkeitsanforderungen ansehen. Braucht der übernommene Code eine solche Anforderung,
dann als **eigene offene CI-Aufabe** mit Bezug auf den Commit festhalten, nicht in der
Auslassungszeile verstecken. Der Nicht-CI-Teil des Commits wird trotzdem übernommen.

## Offene CI-Aufgaben (aus ausgelassenen CI-Dateien)

| Quelle | Abhängigkeitsanforderung | Status |
|---|---|---|
| `xorg/main:.gitlab-ci/debian-install.sh:139` | `xorgproto >= 2025.1` für `_X_FALLTHROUGH` | **offen, entschärft.** `wip/fallthrough` (2b88bbc487) baut inzwischen über ein privates Fallback-Makro in `include/fallthrough.h` grün, ohne ABI-Exposition. Offen bleibt die Rücknahme: sobald xorgproto >= 2025.1 verfügbar ist, das Makro löschen statt überschreiben. Debian/Devuan führt heute nur 2024.1, die Hebung ist also ein eigener Vorgang über alle Lanes. |
| `xorg/main:.gitlab-ci.yml` (`b9f65a275d`, Lauf 2026-10-07) | `ruff`-Durchsetzung in unserer GitHub-CI (`uvx ruff check`) | **offen.** Die Ruff-Commits `6aa23cf642` / `2c53e65004` / `eb9292efdb` werden auf `master` übernommen, der zugehörige Job fällt mit dem GitLab-CI-Teil weg. Gemessen: unsere `.github/workflows` enthalten **kein** `ruff`. Ohne Job ist der Zustand nur per lokalem Lauf prüfbar; die Fassung eines Ruff-Verstoßes würde kein CI-Lane sehen. |

## Gegenprüfungshinweis (DUP-Kriterium)

`git cherry` meldet `316321933a` als fehlend, weil unser Fix ein eigener Patch
ist und kein Cherry-Pick des upstream-Commits. **Patch-äquivalent ist nicht
inhaltliche Enthaltenheit.** Vor dem Einreichen eines "gleiche Funktion"-Commits
prüfen, ob unser master den gleichen Codepfad bereits behebt.

## Bauregel auf Release-Zweigen (ab 2026-09-28)

Build wie die CI: `-Dwerror=true`, nicht `-Dwerror=false`. Die alte Empfehlung
`-Dwerror=false` (wegen `os/Xtranssock.c:631 -Werror=format-truncation`) hat
genau den Mechanismus abgeschaltet, mit dem die CI toten Code findet
(`-Wunused-function` auf FreeBSD/DragonFly, gefunden 2026-09-28 an den
Backports 3759/3760). Ein Fehler, den nur ein bestimmter Compiler mit
bestimmten Flags sieht, sieht ein lokales Setup ohne diese Flags per
Definition nicht.

Erlaubte Ausnahme: **genau ein Eintrag**, `os/Xtranssock.c:631
-Werror=format-truncation` (vorbestehend, kein Backport). Alles andere ist
der zu prüfende Backport.

## Eigene Dokumentation ist Hypothese, nicht Evidenz

Eine Anweisung, die wir selbst geschrieben haben (Build-Empfehlungen,
Auslass-Kriterien, `.backport-skips`-Vorschlag), ist keine Evidenz, sie ist
eine Hypothese. Gegen eine Messung halten, nie übernehmen. Das galt beim
`-Dwerror=false`-Fehler und bei der Annahme, `test/pyxtest` sei nicht auf
den Releases (war es doch, Messung: 42 Einträge auf 25.2).
| `4ef1b4cd26` | RegionValidate: Fix double free of badreg->data on the error path | DUP | Lauf 2026-10-07, Ziel 25.2. Der Fix `badreg->data = NULL` steht auf 25.2 bereits in `dix/region.c:1318` (eingefuehrt durch Backport #3805 / unser #3794). Der Commit ist auf 25.2 **patch-identisch** anwendbar, aber der Inhalt ist bereits vorhanden. |
| `da72833185` | damage: Unlink a damage from the list it was actually inserted on | DUP | Lauf 2026-10-07, Ziel 25.2. `pListDrawable` existiert auf 25.2 in `miext/damage/damagestr.h` und `miext/damage/damage.c` (8 Vorkommen); `DamagePtr *pListHead` existiert mit 0 Treffern. Unser Fix #3813 ist bereits gemergt. Aufnehmen wuerde ein Duplikat erzeugen. |
| `cf91b97d6c` | Xi: byte-swap DeviceChanged valuator and scroll data | DUP | Lauf 2026-10-07, Ziel 25.2. `SDeviceChangedEvent()` in `Xext/xinput/extinit.c` enthaelt den `XIScrollClass`-Case identisch mit den swapl/swaps aus diesem Commit (`scroll_type`, `flags`, `increment.integral`, `increment.frac`). Die Byte-Swap-Umschaltung fuer ScrollClass existiert also bereits auf 25.2. |


| `bdb14dce4b` | xkb: Guard XkbAdjustGroup() against a keymap with no groups | DUP | xkb-Serie (`Guard XkbAdjustGroup` = `ef301a19b5`), bereits auf `release/25.2`. |
| `8e11715024` | xkb: Default to one group whenever a keymap reports none | DUP | `Default to one group` = `ae9edc74fd`, bereits auf `release/25.2`. |
| `aa0bc93d27` | xkb: Never recompute a keymap's group count down to zero | DUP | `Never recompute a keymap's group count down to zero` = `43573b91ad`, bereits auf `release/25.2`. |
| `0c764d98ee` | xkb: Keep the group counts of a loaded keymap in range | DUP | `Keep the group counts of a loaded keymap in range` = `3c7e4e3cf3`, bereits auf `release/25.2`. |
| `8033c4d93e` | Xi: byte-swap XIQueryDevice ScrollClass flags | DUP | ScrollClass-Byte-Swap-Fix ist auf `release/25.2` bereits enthalten. |
| `e19e86c29f` | modesetting: save cursor in master's sprite_priv instead of slave's | DUP | `msGetSpritePriv()` ist auf `release/25.2` bereits als Funktion vorhanden, nicht mehr als Makro — der Commit wandelt das Makro in eine Funktion mit GetMaster()/IsFloating-Umschreibung um, und die Funktion + drei Aufrufe existieren dort (`drmmode_display.c:5011`, `:5047`, `:5060`). |
| `d307f3b4ec` | glx: Allow disabling DRI glx backends | DUP | Die Option existiert auf `release/25.2` bereits: `meson_options.txt:41` `option('glx_dri', ...)` **und** `:44` `option('glx', type: 'boolean', value: true)`. Der Commit fuehrt genau diese Option ein, die hier schon steht. |
| `b522485155` | glamor/glamor_egl: Add a fallback path to `glamor_gbm_bo_from_pixmap` | DUP | Der Fallback-Block existiert auf `release/25.2` vollstaendig: `eglExportDMABUFImageQueryMESA`/`eglExportDMABUFImageMESA` (4 Treffer in `glamor/glamor_egl.c`), `GBM_MAX_PLANES` (20 Treffer), und der Branch `if (ret || !glamor_egl->has_image_dma_buf_export)` (Zeile 863). `glamor_gbm_bo_from_pixmap_internal` existiert als Funktion (Zeile 841). |


| `dc8e08825a` | meson: only install dri3.h if building dri3 support | N-A | Lauf 2026-10-07, Ziel 25.2. `hdrs_dri3` = **0 Treffer** auf `origin/release/25.2`; `dri3/meson.build` existiert bei uns nicht (Zielpfad `Xext/dri3/meson.build` ohne `hdrs_dri3`). Die dri3.h-Installation laeuft bei uns ueber `include/meson.build:453`. Der Commit klammerte nur `install_data(hdrs_dri3,...)` — Zielcode fehlt. Entscheidung: N/A (Voraussetzungs-/Zielcode fehlt).  **Ziel 25.0 (Lauf 2026-10-08): N-A trifft NICHT zu** — `hdrs_dri3` existiert dort (`dri3/meson.build`, 2 Treffer), Commit waere anwendbar. Skip fuer 25.0 = **NEIN** (Build-Hygiene, kein Release-Build-Break), nicht N-A. |
| `84908e8db5` | Fix fragile check for when to build glamor_egl | DUP | Lauf 2026-10-07, Ziel 25.2. Der Commit tauscht `if gbm_dep.found()` gegen `if build_glamor`; unsere Fassung steht bereits auf `if build_glamor` (`hw/xfree86/drivers/video/modesetting/meson.build:37`). Leer-Pick.  **Ziel 25.0 (Lauf 2026-10-08): DUP trifft NICHT zu** — dort steht noch `if gbm_dep.found()` (`hw/xfree86/drivers/modesetting/meson.build:35`), also anwendbar. Skip fuer 25.0 = **NEIN** (Build-Check-Hygiene, kein Build-Break). |
| `5422247702` | Fix incorrect uses of GLAMOR_HAS_GBM | N-A | Lauf 2026-10-07, Ziel 25.2. Der Commit tauscht `#ifdef GLAMOR_HAS_GBM` gegen `#ifdef DRI2` in `hw/xfree86/drivers/modesetting/{dri2.c,driver.c}` (upstream-Pfade). Bei uns auf 25.2: `GLAMOR_HAS_GBM` = **0 Treffer** in `video/modesetting/dri2.c` UND `driver.c` (wir haben dort `#ifdef GLAMOR`); die drei Dateien mit `GLAMOR_HAS_GBM` bei uns sind `glamor/glamor_egl.c`, `glamor/glamor_egl_priv.h`, `include/meson.build` — die faellt der Commit NICHT an. Entscheidung: N/A. **Hinweis fuer 25.1:** dort stehen `GLAMOR_HAS_GBM` 2x in dri2.c und 12x in driver.c — Commit dort anwendbar. Zwei Zweige, zwei Antworten.  **Ziel 25.0 (Lauf 2026-10-08): AUFGENOMMEN** (`a807055d24` im Inkubator) — dort `GLAMOR_HAS_GBM` 2x in dri2.c + 12x in driver.c (Zustand wie 25.1), also anwendbar und Bugfix. Die N-A gilt nur fuer 25.2/master. |

| `5dc9efd5a1` | randr: fix size and offset in RRChangeProviderProperty PrependMode | DUP | Lauf 2026-10-07, Ziel 25.2. Auf `Xext/randr/rrproviderproperty.c` steht der Fix bereits: `new_value.size = total_len` (Zeile 186) und `memcpy((char *) new_data, (char *) value, len * size_in_bytes)` (Zeile 207) — die beiden Lebensadern des Commits. Der Cherry-Pick scheitert nur noch am Whitespace einer Zeile; die Wirkung ist da. |

| `ddf3edc368` | test/pyxtest: cover unbounded DEVICE_RESOLUTION SwapLongs | NEIN | Nur Test-Coverage zu einem bereits enthaltenen Fix (d509580d02). Release-Regel: Test-Churn nicht auf Release. |
| `18dbde8971` | Xi: test XIQueryDevice values for relative scroll valuators | NEIN | Nur Test-Zusatz, kein Bugfix. Release-Regel: nur Bugfixes. |
| `3983c7408c` | meson: convert remaining `foo == a or foo == b` to `foo in [a, b]` style | NEIN | Stil/Refactoring. Release-Regel: kein Stil/Refactoring. |
| `350ef434af` | xfree86: fix modesetting symbols leak test | NEIN | Test-Fix, kein Produktiv-Bugfix. |
| `cd79f876b1` | pyxtest: abstract the present xclients | NEIN | Test-Refactoring. |
| `f8af92cac4` | config: remove the fdi2iclass.py script | NEIN | Skript-Entfernung/Cleanup. |
| `5b22bb635b` | Generalize glamor dependencies | NEIN | Refactoring (Feature-Test-Verallgemeinerung). |
| `a0eec5417c` | Remove redundant define | NEIN | Cleanup/Refactoring. |
| `61e546b113` | Generalize GBM feature tests | NEIN | Test-Refactoring. |
| `797221a3a9` | Generalize epoxy feature tests | NEIN | Test-Refactoring. |
| `1fcee9582d` | Expose libxcvt availability to compiled code | NEIN | Build-Plumbing, kein Bugfix. |
| `effe0ba3cd` | test: cover an incomplete keymap in XkbGetKbdByName | NEIN | Test-Zusatz zum aufgenommenen Fix 6a4fb12019, kein eigener Bugfix. |

## Lauf 2026-10-08 — Ziel `release/25.0` (XL-0, Praetor-Freigabe Phase I+II)

Stand: Intervall `867976ba87..ad26c26bf7` = **72 Commits**, davon **24 aufgenommen**
(Inkubator `rfc/backport-25.0` = `9078c564a0`), **48 ausgelassen** (dokumentiert).
Tracker `tracking/xorg/main-on-25.0` = `ad26c26bf7` (= xorg/main), Intervall danach **0**.
Build: `-Dwerror=true`, nur die dokumentierten 4 lokalen 25.0-Vorbestaende
(`glx/unpack.h:126+127` via `glxcmds.c`, `os/connection.c`, `os/xstrans.c`) — A/B gegen
`origin/release/25.0` gemessen, identische Fehlermenge. Trailer: 24/24 `Signed-off-by`
= Original-Autor, 24/24 `Part-of`, 24/24 `(cherry picked from ...)`.

Neu entschieden (Zeilen fehlten bisher):

| SHA | Subject | Kriterium | Begruendung |
|---|---|---|---|
| `306071c0b9` | xf86: mark wasset unused in xf86UnblockSIGIO() compatibility wrapper | NEIN | Warnungs-Hygiene ohne Verhaltensaenderung, kein Bugfix (m0137: nur nach Maintainer-Ruecksprache). Unsere Lanes bauen ohne `-Wextra` — der Warning faellt hier nicht an. |
| `495ea74203` | test: fail when a child terminates abnormally | NEIN | Test-Churn auf Release (Release-Regel). Zudem inhaltlich unser eigener Master-#3777 mit eigenem Task (`task-backport-3777-to-release-25-0`) — die xorg-Fassung wird nicht dubliziert uebernommen. |
| `cfbc5224a6` | rootless: Remove ROOTLESS_WORKAROUND | NEIN | Entfernung/Refactoring (nur hw/xquartz), kein Bugfix. |

Ergaenzend fuer diesen Lauf (Kriterien gelten ueber die Ziel-Zeilen hinaus):

- **DUP fuer 25.0 zusaetzlich gemessen** (Inhalt auf `origin/release/25.0` vorhanden):
  `d509580d02` (`d9f34d33eb` + Bound `Xi/chgdctl.c:99`), `cf91b97d6c` (`22ee2f625b`),
  `8033c4d93e` (`a781f82356`), `4ef1b4cd26` (`74e8a35363`), `da72833185`
  (`pListDrawable` 8+1 Treffer), `9d068f0efb` (`6851e17816` + `option('tests')`),
  `5dc9efd5a1` (`new_value.size = total_len`, `randr/rrproviderproperty.c:185`),
  `bdb14dce4b`/`8e11715024`/`aa0bc93d27`/`0c764d98ee` (`550d302caa`/`d7f6112eb2`/
  `d2d51b35a8`/`f425a94483`), `e19e86c29f` (`51b6f5ad00`), `14981eea44` (Leer-Pick,
  Zeile fehlt dort), `316321933a` (calloc-Guard in `glamor/glamor_core.c:111-120`,
  Patch-ID weicht ab — Inhalt da), `ecb6644fdd`/`bbe30db5c0` (25.0 steht bereits auf
  `28.0`/`11.0`).
- **`efcfd8acc7` (Xi gesture sprite traces) war als NEIN eingetragen und ist FALSCH:**
  der Commit-Body ist **CVE-2026-93536 / ZDI-CAN-32753** (UAF in
  `WindowGone`, client-ausloesbar) — Security-Fix, auf 25.0 aufgenommen
  (`e55bcbe224`). Die NEIN-Zeile wurde geloescht; Subjekt-Lesung ohne Body war der
  Fehler. Gegen jede andere rein-cleanup-klingende NEIN-Zeile denselben Body-Check
  machen, bevor man sie uebernimmt.
- **Nebenjobs-Grenze:** `3c62ee0c78` = DUP ueber PR #3867 (offen), `495ea74203` liegt
  im eigenen Task #3777 — der xorg-Lauf entscheidet ueber beide nicht.

## Lauf 2026-10-09 — Ziel `master` (Defiant, Praetor-Freigabe Option b)

Stand: Intervall `b125b19fc2..ad26c26bf7` = **39 Commits**. xorg/main = `ad26c26bf7`.
Tracker `tracking/xorg/main-on-master` stand auf `b125b19fc2` (39 Rueckstand).
Inkubator `rfc/backport-master` **lokal aufgebaut, NICHT gepusht** (Freigabe ausstehend).
Build `-Dwerror=true` **gruen** (meson/ninja, `_WORK_/xserver-master/target` als Prefix).
Trailer: 22/22 aufgenommene xorg-Commits mit `Signed-off-by` (Original-Autor) + `Part-of`.

**Aufgenommen (22):** `f37bd8de26`, `cd79f876b1`, `cd083d9659`, `2b9ce9f6c6`,
`0d1b1b0bad`, `b941a473e0`, `89101a6c66`, `cea71d0273`, `2abe4632d7`, `1b6955c310`,
`ad26c26bf7`, `7a0b3e2197`, `bad7edcab0`, `6a4fb12019`, `37a1847a60`, `be57263415`,
`1f42cc1f00`, `efcfd8acc7` (alle Security/Bugfix), ruff-Block `6aa23cf642`,
`2c53e65004`, `eb9292efdb` (nur `hw/xwin/glx/gen_gl_wrappers.py`; `.gitlab-ci*`-Teile
verworfen, Dateien existieren bei uns nicht), `f8af92cac4` (fdi2iclass.py entfernt;
`COPYING` = ours, unsere Lizenzliste divergiert).

**Ausgelassen (17):**

| SHA | Subject | Kriterium | Begruendung |
|---|---|---|---|
| `b9f65a275d` | ci: Run ruff check against the whole tree | GHC | Dateiliste ist genau `.gitlab-ci.yml`, existiert bei uns nicht. Ruff-Lauf bleibt offene CI-Aufgabe. |
| `9d068f0efb` | meson: option to disable tests | DUP | `option('tests')` + `and build_xserver` bereits auf master (`6851e17816`). |
| `d307f3b4ec` | glx: option to disable DRI glx backends | DUP | `option('glx_dri')` bereits auf master. |
| `5dc9efd5a1` | randr: PrependMode size/offset | DUP | `new_value.size = total_len` bereits (`rrproviderproperty.c:189`). |
| `b522485155` | glamor_egl: GBM fallback path | DUP | Fallback-Branch + `has_image_dma_buf_export` bereits auf master (`glamor_egl.c:860`). |
| `84908e8db5` | Fix fragile glamor_egl build check | DUP | master steht bereits auf `if build_glamor`. |
| `a66b0286b3` | glamor: Restore `GetImage` proc | DUP (Leer-Pick) | Inhalt auf master vorhanden. |
| `41b3d993ba` | glamor: Set `need_free_region` … | DUP (Leer-Pick) | Inhalt auf master vorhanden. |
| `5422247702` | Fix incorrect uses of GLAMOR_HAS_GBM | N-A | `GLAMOR_HAS_GBM` 0 Treffer in modesetting auf master; unsere Fassung nutzt `#ifdef GLAMOR`. |
| `309e4d35d8` | modesetting: Restrict hw cursor size | N-A | `min_cursor_width` 0 Treffer auf master; durch `drmmode_probe_cursor_size` abgeloest. |
| `350ef434af` | xfree86: fix modesetting symbols leak test | N-A | meson-Struktur divergiert (unsere `hw/xfree86/meson.build` nutzt `subdir('drivers')`); Symboltest arbeitet mit `join_paths`. |
| `5b22bb635b` | Generalize glamor dependencies | N-A | Build-System divergiert; Refactoring, kein Bugfix. |
| `a0eec5417c` | Remove redundant define | N-A | Build/Cleanup, Konflikt mit unserer Struktur. |
| `61e546b113` | Generalize GBM feature tests | N-A | Build-Refactoring. |
| `797221a3a9` | Generalize epoxy feature tests | N-A | Build-Refactoring. |
| `1fcee9582d` | Expose libxcvt availability | N-A | Build-Plumbing; kein Nutzer auf master. |
| `effe0ba3cd` | test: cover incomplete keymap in XkbGetKbdByName | N-A | Test fuer xorg-Verzeichnislayout (`../../xkb/`); unser `xkb/`→`Xext/xkeyboard/`. Fix `6a4fb12019` ist aufgenommen; Test braucht eigene Portierung. |

**Konsequenz:** Tracker `tracking/xorg/main-on-master` kann auf `ad26c26bf7` gezogen
werden (alle 39 bearbeitet). **Push von `rfc/backport-master` und Tracker erst nach
expliziter Praetor-Freigabe** (Option b: kein Push ohne Freigabe).
