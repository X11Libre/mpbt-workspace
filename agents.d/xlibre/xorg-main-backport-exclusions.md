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
- Ausgelassene Commits werden **nicht** in den Incubator aufgenommen und der
  Tracker **nicht** über sie hinausgezogen.
- Wird ein zuvor ausgelassener Commit doch übernommen (Kriterium entfällt),
  aus der Liste streichen — die Liste ist der Soll-Zustand, nicht ein Log.

## Auslass-Kriterien (Stand 2026-09-28)

| Kürzel | Kriterium | Begründung |
|---|---|---|
| **XWL** | `xwayland` | Bewusst im Baum entfernt (nur hw/xwayland/ berührt) |
| **TEST** | Python-Test-Skripte (`test/*.py`, pyxtest) | Release-spezifisch: für master nicht anwenden (dort vorhanden); für Releases einzeln prüfen, denn `test/pyxtest` existiert auch auf release/25.2 und ist nicht pauschal abwesend |
| **DUP** | Inhaltlich durch eigenen gemergten master-PR abgedeckt | `git cherry` zeigt patch-Äquivalenz, nicht inhaltliche Enthaltenheit |
| **GHC** | GitHub-CI-Konfiguration (`.gitlab-ci/`, `.gitlab-ci.yml`) | Wir haben `.gitlab-ci/` vor Langem entfernt und nutzen nur GitHub CI. **Nur Commits auslassen, die ausschließlich `.gitlab-ci*` betreffen** — CI-Änderungen kommen oft zusammen mit anderen (z. B. Dependency-Anpassung); dann wird der Nicht-CI-Teil übernommen und nur die CI-Dateien fallen weg. Entscheidend ist die **Dateimenge, nicht das Subject**; den ganzen Commit zu verwerfen ist falsch. Messgriff: `git show --name-only <sha>` — nur wenn die Liste **identisch** mit `.gitlab-ci*`-Pfaden ist, auslassen; sonst teill übernehmen. Alternativ als Resttest: `git show --name-only <sha> \| grep -vE '\.gitlab-ci/' \| grep -q .` |

## Ausgelassene Commits

*Momentaufnahme 2026-09-28, master-Tracker auf `867976ba87`, `xorg/main` auf
`b125b19fc2`.*

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
| `bd3ca7da06` | Use _X_FALLTHROUGH macro to silence fallthrough warnings in clang as well | ÜBERTRAGEN | Nicht cherry-pick-bar: 12 Konfliktdateien, keine davon reine Kommentar-Konvertierung (InputClass.c nutzt `negated`, upstream `matchtype`; dix/events.c nutzt `GRAB_STATE_FROZEN_WITH_EVENT`, upstream `FROZEN_WITH_EVENT`; `.gitlab-ci*` existiert bei uns nicht). **Die Arbeit ist auf `wip/fallthrough` erledigt** (Tip 2b88bbc487): 35 Vorkommen von `/* fallthrough */`, `/* fall through */`, `/* fall-through */`, `/* FALLTHROUGH */` in 16 Dateien sind zu `_X_FALLTHROUGH; /* fallthrough */` ersetzt, plus ein privates Fallback-Makro in `include/fallthrough.h`. **Baut grün** (meson/ninja, `-Dwerror=true`, 629/629). **Das Fallback-Makro wird mit xorgproto >= 2025.1 überflüssig und ist dann zu löschen, nicht zu überschreiben** — siehe offene CI-Aufabe. |

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