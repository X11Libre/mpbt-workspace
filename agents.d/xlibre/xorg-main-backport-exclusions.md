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
| `316321933a` | glamor: free the link log on shader link failure | DUP | Inhaltlich durch gemergten PR 3750 (`482f7b326d`) abgedeckt; unser Fix ist vollständiger (bringt den calloc-Guard mit) |

## Gegenprüfungshinweis (DUP-Kriterium)

`git cherry` meldet `316321933a` als fehlend, weil unser Fix ein eigener Patch
ist und kein Cherry-Pick des upstream-Commits. **Patch-äquivalent ist nicht
inhaltliche Enthaltenheit.** Vor dem Einreichen eines "gleiche Funktion"-Commits
prüfen, ob unser master den gleichen Codepfad bereits behebt.