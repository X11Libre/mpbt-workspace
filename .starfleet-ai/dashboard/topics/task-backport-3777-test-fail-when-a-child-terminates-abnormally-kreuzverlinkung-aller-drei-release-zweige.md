---
Title: "Backport #3777 (test: fail when a child terminates abnormally) — Kreuzverlinkung aller drei Release-Zweige"
Category: active
Kind: task
Status: open
Assigned-To: "Scotty"
Created-By: "Enterprise"
Created: 2026-10-02T00:00:00Z
Doc-Ref: "—"
---

Anker-Topic fuer den Backport von **Master-PR #3777** auf alle drei
Release-Linien. Die drei Zweig-Topics existieren bereits; **dieses hier traegt die
Kreuzverlinkung**, damit Master-PR und alle drei Backports in einer Sicht liegen.

**Verknüpft mit:**
- Master-PR: https://github.com/X11Libre/xserver/pull/3777
- Batch: `task-backport-batch-2026-10-01-3776-3777-3779-auf-release-25-2-25-1-25-0`
- Audit: `task-audit-2026-10-01-fehlende-backports-nach-heutigem-merge-xkb-serie-25-2-3779-nach-25-0-3775-alle-branches`
- Offener Folge-Bug: `task-locale-abhaengige-assertion-in-test-signal-logging-c-213-masst-abgestuerzte-unit-tests-als-pass-auf-release-25-0-und-25-1-beleget`
- Zweig-Topics: `task-backport-3777-to-release-25-0`, `...-25-1`, `...-25-2`

## Kreuzverlinkung

| Branch | PR | Commit | Zweig-Topic | CI | Review |
|---|---|---|---|---|---|
| release/25.2 | [#3800](https://github.com/X11Libre/xserver/pull/3800) | `92c7342d7bbe` | `task-backport-3777-to-release-25-2` | 28 success, 0 fail | passed |
| release/25.1 | [#3798](https://github.com/X11Libre/xserver/pull/3798) | `adc5f461d085` | `task-backport-3777-to-release-25-1` | **xserver-build-ubuntu fail ×2**, 15 success | passed |
| release/25.0 | [#3797](https://github.com/X11Libre/xserver/pull/3797) | `98ddb67eb408` | `task-backport-3777-to-release-25-0` | **xserver-build-ubuntu fail ×2**, 4 success | passed |

Alle drei: ein Commit, eine Datei (`test/tests-common.c`), Sign-off
**Lukáš Lipinský** — fremder Patch, Originalautor, genau einer.

## CI auf 25.0/25.1 ist erwartet und kommt NICHT vom Backport

Das ist der Punkt, den ein Merge-Entscheider kennen muss:

    tests: ../test/signal-logging.c:213: logging_format:
      Assertion `strcmp(&logmsg[strlen(logmsg) - 3], "en\n") == 0' failed.
    13/16 xserver / unit   FAIL   0.28s

**Locale-abhängig** — verlangt, dass die Logzeile auf den englischen Locale-Suffix
endet. Steht in `test/signal-logging.c`, der Backport ändert `test/tests-common.c`:
**disjunkte Dateien**, also keine Berührung.

Was dieser Backport tut, ist eine **Maske abzunehmen**. Vorher meldete
`run_test_in_child()` ein abnormal beendetes Kind mit `exit(exit_code)`, wobei
`exit_code` über das `goto child_failed` hinweg den Wert des **vorherigen** Tests
behielt — bei 0 also `exit(0)`, und `meson test` meldete **PASS**. Deshalb ist der
Tip von `release/25.1` grün, während der Backport rot ist: **der Tip ist grün,
weil Fehlschläge nicht durchkamen.**

Auf 25.0 ist der Tip ebenfalls rot (am Branch-Tip verifiziert), dort war der Fehler
also schon sichtbar.

**Der zugrunde liegende Test-Bug ist damit offen** und als eigenes Topic erfasst.
Dieser Backport behebt ihn nicht, und er behauptet es auch nicht.

## Abnahmekriterium

1. Ein Dashboard-Topic **pro PR** — dafür existieren die drei Zweig-Topics.
2. Jeder PR nennt im **PR-Body** seinen Topic-Slug **und** verlinkt zurück.
3. Dieses Anker-Topic verlinkt Master-PR und alle drei Backports (siehe Tabelle).
4. Sign-off-Zahl == 1, Autor == Originalautor.
5. `git rev-list --count origin/release/<ziel>..HEAD` == 0.
6. Erst bei Commit + Topic + Verlinkung in beide Richtungen wird ein Haken gesetzt.

## Merge

release/* wird **nie** automatisch gemergt. Review, Kommentar, Label, dann Stopp.
Merge macht der Maintainer. Stand 2026-10-02: **keiner der drei gemergt.**
