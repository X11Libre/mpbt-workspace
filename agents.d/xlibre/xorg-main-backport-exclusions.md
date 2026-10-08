# xorg/main Backport — Auslassungs-Konvention

Versioniertes Verzeichnis der **bewusst ausgelassenen** `xorg/main`-Commits im
xorg/main-Backport-Workflow (siehe Skill `backport-xorg-main`).

Dieses File ist der dauerhafte, versionierte Anker für den Zustand "bewusst
ausgelassen" — der im Branch-Modell keine eigene Spur hat (gemergt faellt via
Rebase aus der Queue, offener PR trägt `[PR #NNNN]`, Auslassung ist sonst
unsichtbar). Es lebt im Workspace-Repo (`agents.d/`), nicht in einem Clone und
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
| `3c62ee0c78` | modesetting: Fix use-after-free when aborting queued events | DUP | Leer-Pick: unser vblank.c hat bereits `if (!q->aborted && match(...))` (Zeile 551) und das `aborted`-Feld an 4 Stellen — der UAF-Fix ist schon enthalten. |
| `14981eea44` | Xnest: do not reset pScreen->devPrivate to NULL | DUP | Leer-Pick: unser hw/xnest/Screen.c enthält die `pScreen->devPrivate = NULL`-Zeile bereits nicht (nur `dixSetPrivate(&pScreen->devPrivates, ...)`). |
| `b9f65a275d` | ci: Run ruff check against the whole tree | GHC | Lauf 2026-10-07, Intervall `b125b19fc2..ad26c26bf7`, Ziel `master`. Dateiliste gemessen: **genau eine Datei**, `.gitlab-ci.yml` — damit ist das GHC-Kriterium erfüllt (Dateimensge, nicht das Subject). CI-Inhalt: Job `ruff-check` mit `uvx ruff check`, **keine** Abhängigkeits-Installation. Der zugehörige Ruff-Block (`6aa23cf642`, `2c53e65004`, `eb9292efdb`) ist echter Quellcode und wird übernommen; die fehlende Durchsetzung steht als offene CI-Aufgabe unten. |
| `9d068f0efb` | meson.build: meson_options.txt: add build option to disable building tests | DUP | Lauf 2026-10-07, Ziel `master`. Bereits vorhanden: `meson_options.txt:128` `option('tests', …)` **und** `meson.build:847` `if (get_option('tests') and host_machine.system() != 'windows' and build_xserver)` — gebracht von unserem `6851e17816` mit gleichem Subject. Die Patch-IDs unterscheiden sich (unser Check ist strenger: zusätzlich `and build_xserver` plus Klammern), deshalb meldet `git cherry` den Commit fälschlich als fehlend — **Patch-Äquivalenz ist nicht inhaltliche Enthaltenheit**, genau der dokumentierte DUP-Fall. Aufnehmen würde `and build_xserver` entfernen (Regression: Tests auch ohne Server-Gebäude). Zusätzlich alignierter Konflikt in `meson_options.txt`: die von upstream mitgezogene `xf86-input-inputtest`-Option existiert bei uns bereits (Zeile 172), ein Take-theirs hätte sie doppelt definiert. |
| `71c7824e80` | meson: check cpu_family() instead of cpu() | DUP / ENTSCHEIDUNG | Lauf 2026-10-07. **Praetor-Entscheidung: „koennen wir getrost weglassen"** (morgige Console). Zusaetzlich gemessen: auf `master` ist der Inhalt bereits da — unsere eigene PR #3780 ist gemergt (`ca2b7f19fc`), `meson.build` führt `cpu_family()` dreimal, kein `cpu()` mehr; dort wäre es also auch DUP. Auf den **Release-Zweigen ist die Aenderung dagegen abwesend** (`release/25.2`: 0 Treffer; unsere Backports #3815/#3816/#3817 sind `CLOSED`, nicht gemergt) — dort beruht der Ausschluss **allein auf der Entscheidung**, nicht auf inhaltlicher Enthaltenheit. Bewusst so vermerkt, damit der nächste Lauf nicht „fehlt doch" meldet und jemand nachliefert. |
| `309e4d35d8` | modesetting: Restrict hw cursor size optimization to known working hw | N-A | Lauf 2026-10-07, alle Ziele. Die eingeschraenkte Maschine stammt aus `1f41320e1c42` und existiert bei uns **nicht mehr**: `min_cursor_width` gemessen mit 0 Treffern auf `origin/master` **und** auf `origin/release/25.2`; unsere Cursor-Größen-Ermittlung laeuft ueber `drmmode_probe_cursor_size` + `dimensions[]` (abgeloest durch `05c63d2a02`, `e6c980f08e`). Aufnehmen wuerde die neue Option `CursorSizeOptimization` samt `allow_cursor_size_optim`-Feld einfuegen, das bei uns niemand aufruft — toter Code plus Feature. Entscheidung: N/A. Umkehr (die Einschraenkung an unsere Probe-Mechanik anpassen) waere eine Feature-Entscheidung des Praetors und gehoert in den Entscheidungs-Report, nicht in einen Lauf. |
| `bd3ca7da06` | Use _X_FALLTHROUGH macro to silence fallthrough warnings in clang as well | ÜBERTRAGEN | Nicht cherry-pick-bar: 12 Konfliktdateien, keine davon reine Kommentar-Konvertierung (InputClass.c nutzt `negated`, upstream `matchtype`; dix/events.c nutzt `GRAB_STATE_FROZEN_WITH_EVENT`, upstream `FROZEN_WITH_EVENT`; `.gitlab-ci*` existiert bei uns nicht). **Die Arbeit ist auf `wip/fallthrough` erledigt** (Tip 2b88bbc487): 35 Vorkommen von `/* fallthrough */`, `/* fall through */`, `/* fall-through */`, `/* FALLTHROUGH */` in 16 Dateien sind zu `_X_FALLTHROUGH; /* fallthrough */` ersetzt, plus ein privates Fallback-Makro in `include/fallthrough.h`. **Baut grün** (meson/ninja, `-Dwerror=true`, 629/629). **Das Fallback-Makro wird mit xorgproto >= 2025.1 überflüssig und ist dann zu löschen, nicht zu überschreiben** — siehe offene CI-Aufabe. |
| `d509580d02` | Xi: bound SwapLongs of resolution values to the request length | DUP | Lauf 2026-10-07, Ziel 25.2. Gemessen am Zweiginhalt statt am Patch: der Bound steht auf `release/25.2` bereits **vor** dem `SwapLongs` (`if ((len < bytes_to_int32(sizeof(xDeviceResolutionCtl))) \|\| (len != bytes_to_int32(...) + r->num_valuators))` bei `Xext/xinput/chgdctl.c:109-114` vs `SwapLongs` bei :131). Zusaetzlich existiert `SProcXChangeDeviceControl` auf 25.2 **nicht als eigene Funktion** — der Swap laeuft inline unter `client->swapped`. Die Wirkung des Fixes ist damit schon da; `git cherry` meldet ihn trotzdem als fehlend (Patch-Aequivalenz != inhaltliche Enthaltenheit). |
| `be57263415` | dix: remove passive grabs referencing a device on removal | N-A | Lauf 2026-10-07, Ziel 25.2. `GrabReferencesDevice` gemessen mit **0 Treffern** auf `origin/release/25.2` — die Funktion, die dieser Commit einfuehrt (Pruefer-Funktion fuer passive Grabs ueber die dont-remove-a-device-Referenz), gibt es dort nicht. Genauso `RemovePassiveGrabsForDevice`. Der Commit setzt eine maschine voraus, die 25.2 nicht hat; aufnehmen hiesse, fremden Code samt toter Helfer einzubauen. Entscheidung: N/A (Voraussetzungs-/Zielcode fehlt). |

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

