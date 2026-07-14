---
title: "starfleet-dispatch: informativen Text für transiente API-Fehler Restart-Prompts"
category: active
kind: task
status: "in_progress"
tags: "starfleet,plugin,error-handling"
---

## Problem

Bei transienten API-Fehlern injiziert das Plugin `starfleet-dispatch.ts` den Text
`"Please continue."` als synthetisches Prompt-Part. Dieser Text ist zu generisch —
er vermittelt keinen Kontext über das geschehene Ereignis.

Zusätzlich: Model-Switch-Commands (`model <model>`) von McKinley/Enterprise
werden nicht verarbeitet, weil sie als type="ship" gesendet werden und das
Plugin nur `setmodel` (nicht `model`) als Präfix in ship/user/control-Nachrichten
erkennt.

## Fix 1: Model-Switch Commands in ship/user/control Nachrichten

**Datei:** `.starfleet-ai/src/starfleetctl/fragments/opencode-plugins/starfleet-dispatch.ts`

Erweitert `handleMessage()` um `model ` Präfix-Erkennung (neben `setmodel`):
- Zeile 155-177: Beide Präfixe (`setmodel ` und `model `) werden jetzt
  in ship/user/control-Nachrichten erkannt und als Model-Switch ausgeführt

## Fix 2: seen_mark Handler in Go Dispatch

**Datei:** `.starfleet-ai/src/starfleetctl/internal/comms/dispatch.go`

- Zeile 144-145: `seen_mark` Case im `dispatch()` Switch hinzugefügt
- Zeile 460-475: `dispatchSeenMark()` Funktion implementiert
  (ruft `DoAck` auf, um Nachricht von unseen/ nach seen/ zu verschieben)

## Implementierungs-Status

- [x] Plugin-Quelle editiert (model + setmodel Prefix-Erkennung)
- [x] Go Dispatch-Code editiert (seen_mark Handler)
- [x] starfleetctl Binary neu gebaut
- [x] Fragments via `bootstrap --fix` deployed
- [ ] Verifikation: Model-Switch funktioniert mit `comms tell Voyager "model <model>"`
- [ ] Verifikation: seen_mark wird vom Plugin ohne Fehler verarbeitet
