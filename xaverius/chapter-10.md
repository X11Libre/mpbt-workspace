# XAverius v0.1 — Kapitel 10: Registries und numerische Konstanten

## 10.1 Allgemeine Regeln

Dieses Kapitel definiert die numerischen Registries für XAverius v0.1. Alle hier festgelegten Werte sind innerhalb ihrer jeweiligen Registry stabil.

Numerische Werte aus unterschiedlichen Registries sind voneinander unabhängig. Derselbe Zahlenwert kann daher in zwei Registries unterschiedliche Bedeutungen haben.

Reservierte Werte MUST NOT gesendet werden. Empfänger MUST unbekannte, nicht reservierte Werte als unbekannt behandeln und MUST NOT ihnen eigenmächtig eine bekannte Bedeutung zuweisen.

Standard-X11-Fehlercodes werden verwendet, wenn ein Standard-X11-Fehler den Fehler angemessen beschreibt. XAverius-spezifische Fehlercodes werden nur für Fehler verwendet, die nicht angemessen durch einen Standard-X11-Fehler abgedeckt sind. Die tatsächlichen X11-Erweiterungsfehlercodes werden durch den X-Server zugewiesen; diese Registry definiert symbolische XAverius-Codes und nicht die serverseitigen absoluten Fehlernummern.

## 10.2 XAverius-Fehlercodes

Diese Registry definiert die Werte des Feldes `error_code` in `ASYNC_ERROR`. Sie kann außerdem für synchron gemeldete XAverius-spezifische Fehler verwendet werden, sofern die jeweilige Request-Spezifikation dies ausdrücklich festlegt.

| Wert | Name | Bedeutung |
|---:|---|---|
| 1 | `DEVICE_UNAVAILABLE` | Das referenzierte Gerät ist nicht verfügbar |
| 2 | `DEVICE_LOST` | Das logische Gerät hat einen Geräteverlust erlitten |
| 3 | `INVALID_SYNCHRONIZATION_STATE` | Ein Synchronisationszustand ist ungültig |
| 4 | `EXECUTION_FAILED` | Eine angenommene GPU-Operation ist fehlgeschlagen |
| 5 | `TRANSFER_FAILED` | Ein Buffer-Transfer ist fehlgeschlagen |
| 6 | `ALLOCATION_FAILED` | Eine Speicherallokation oder interne Ressourcenreservierung ist fehlgeschlagen |
| 7 | `DEPENDENCY_FAILED` | Eine erforderliche asynchrone Abhängigkeit ist fehlgeschlagen |
| 8 | `INTERNAL_SERVER_ERROR` | Ein nicht näher klassifizierter interner Fehler ist aufgetreten |

Der Wert `0` sowie die Werte `9–31` sind reserviert. Werte ab `32` sind für spätere Versionen oder registrierte Erweiterungen vorgesehen.

Ein Request, der synchron abgewiesen wird, darf nicht zusätzlich als asynchroner Fehler gemeldet werden, sofern der Request nicht zuvor erfolgreich angenommen wurde und die Spezifikation für diesen Vorgang ausdrücklich eine spätere Fehlerbenachrichtigung vorsieht.

## 10.3 Event-Typen

Alle XAverius-Events werden als X Generic Events (XGE) übertragen. Das `extension`-Feld identifiziert den XAverius-Major-Opcode; `evtype` identifiziert den Event-Typ.

| `evtype` | Name | Auswahl |
|---:|---|---|
| 0 | `ASYNC_ERROR` | Immer zugestellt |
| 1 | `DEVICE_LOST` | Immer zugestellt |
| 2 | `DEVICE_STATUS_CHANGED` | Verbindungsbezogene Event-Auswahl |
| 3 | `DEVICE_MEMORY_PRESSURE` | Gerätebezogene Event-Auswahl |
| 4 | `DEVICE_IDLE` | Gerätebezogene Event-Auswahl |
| 5 | `SUBMISSION_COMPLETE` | Queue-bezogene Event-Auswahl |
| 6 | `SUBMISSION_FAILED` | Queue-bezogene Event-Auswahl |

Die Werte `7–65535` sind in v0.1 nicht definiert. `ASYNC_ERROR` und `DEVICE_LOST` sind nicht maskierbar. Die übrigen Events werden ausschließlich anhand der jeweiligen Auswahlmaske zugestellt.

### 10.3.1 Event-Auswahlmasken

Die Bitpositionen der Event-Auswahlmasken sind unabhängig von den `evtype`-Werten.

**Verbindungsmaske**

| Bit | Event |
|---:|---|
| 0 | `DEVICE_STATUS_CHANGED` |
| 1–31 | Reserviert |

**Gerätemaske**

| Bit | Event |
|---:|---|
| 0 | `DEVICE_MEMORY_PRESSURE` |
| 1 | `DEVICE_IDLE` |
| 2–31 | Reserviert |

**Queue-Maske**

| Bit | Event |
|---:|---|
| 0 | `SUBMISSION_COMPLETE` |
| 1 | `SUBMISSION_FAILED` |
| 2–31 | Reserviert |

Masken gelten unabhängig pro Verbindung und Zielressource. Eine Maske wird nicht automatisch von einer Ebene auf eine andere übertragen. Unbekannte oder reservierte Bits MUST NOT gesetzt sein.

## 10.4 Ursachencodes für Gerätestatus und Geräteverlust

Das Feld `reason_code` in `DEVICE_STATUS_CHANGED` und `DEVICE_LOST` verwendet diese gemeinsame Registry.

| Wert | Name | Bedeutung |
|---:|---|---|
| 0 | `REASON_UNSPECIFIED` | Ursache unbekannt oder nicht verfügbar |
| 1 | `HOTPLUG_REMOVAL` | Das physische Gerät wurde entfernt |
| 2 | `DRIVER_FAILURE` | Treiberfehler |
| 3 | `VULKAN_DEVICE_LOST` | Vulkan meldet Geräteverlust |
| 4 | `SERVER_POLICY` | Die Serverrichtlinie hat den Zugriff entzogen |
| 5 | `SERVER_SHUTDOWN` | Der Server wird beendet |

`REASON_UNSPECIFIED` ist ein gültiger Wert. Ein Server MUST eine Ursache nicht genauer klassifizieren, als dies durch seine verfügbaren Informationen gerechtfertigt ist.

Das Feld `new_status` in `DEVICE_STATUS_CHANGED` verwendet folgende Werte:

| Wert | Name | Bedeutung |
|---:|---|---|
| 0 | `AVAILABLE` | Das physische Gerät ist verfügbar, vorbehaltlich der Serverrichtlinie |
| 1 | `UNAVAILABLE` | Das physische Gerät ist derzeit nicht verfügbar |
| 2 | `REMOVED` | Die physische Geräteinstanz wurde aus der verfügbaren Gerätemenge entfernt |

`REMOVED` ist für die betreffende physische Geräteinstanz endgültig. Die zugehörige XID MUST NOT einer anderen physischen Geräteinstanz zugewiesen werden. Ein Statuswechsel auf `UNAVAILABLE` führt nicht automatisch dazu, dass bestehende logische Geräte auf ein anderes physisches Gerät umgeleitet werden.

## 10.5 Submission-Fehlerklassen

Das Feld `failure_class` in `SUBMISSION_FAILED` verwendet folgende Werte:

| Wert | Name | Bedeutung |
|---:|---|---|
| 0 | `EXECUTION_FAILED` | Die Submission konnte nicht erfolgreich abgeschlossen werden |
| 1 | `DEVICE_LOST` | Die Submission scheiterte aufgrund eines Geräteverlusts |

Eine Submission MUST NOT sowohl mit `SUBMISSION_COMPLETE` als auch mit `SUBMISSION_FAILED` als abgeschlossen gemeldet werden.

`SUBMISSION_FAILED` ist ein optionales Queue-Event. Der detaillierte Fehlergrund wird über `ASYNC_ERROR` gemeldet, sofern ein solcher Fehlergrund vorliegt und die Regeln für asynchrone Fehlerzustellung dies vorsehen.

## 10.6 Herkunft asynchroner Fehler

Das Feld `origin` in `ASYNC_ERROR` verwendet folgende Werte:

| Wert | Name | Bedeutung |
|---:|---|---|
| 0 | `ORIGIN_UNSPECIFIED` | Herkunft nicht näher bestimmt |
| 1 | `ORIGIN_QUEUE_SUBMIT` | Queue-Submission |
| 2 | `ORIGIN_WRITE_BUFFER` | Buffer-Schreibtransfer |
| 3 | `ORIGIN_READ_BUFFER` | Buffer-Lesetransfer |
| 4 | `ORIGIN_SEMAPHORE` | Semaphore-Operation |
| 5 | `ORIGIN_FENCE` | Fence-Operation |
| 6 | `ORIGIN_DEVICE` | Gerätebezogener Vorgang |

Werte ab `7` sind in v0.1 nicht definiert.

## 10.7 Speicherbelastungsstufen

Das Feld `pressure_level` in `DEVICE_MEMORY_PRESSURE` verwendet folgende Werte:

| Wert | Name | Bedeutung |
|---:|---|---|
| 0 | `NORMAL` | Keine erhöhte Speicherbelastung gemeldet |
| 1 | `LOW` | Niedrige Speicherbelastung |
| 2 | `MEDIUM` | Mittlere Speicherbelastung |
| 3 | `HIGH` | Hohe Speicherbelastung |

Ein Event kann sowohl eine Erhöhung als auch eine Verringerung der Belastungsstufe anzeigen. Das Event ist informativ und stellt keine Garantie für die Verfügbarkeit einer bestimmten Speichermenge dar.

## 10.8 Gründe für `DEVICE_IDLE`

Das Feld `idle_reason` in `DEVICE_IDLE` verwendet folgende Werte:

| Wert | Name | Bedeutung |
|---:|---|---|
| 0 | `IDLE_REASON_UNSPECIFIED` | Grund nicht näher bestimmt |
| 1 | `NO_PENDING_WORK` | Es ist keine vom Server nachverfolgte GPU-Arbeit ausstehend |
| 2 | `WORK_COMPLETED` | Die zuvor ausstehende GPU-Arbeit wurde abgeschlossen |

`DEVICE_IDLE` beschreibt einen Zustand zum Zeitpunkt des Events. Es verhindert keine späteren Submissions und ersetzt weder `DeviceWaitIdle` noch eine andere explizite Synchronisationsoperation.

## 10.9 Event-Längen und Payloads

Für alle folgenden Events gelten die standardmäßigen 32 Byte des XGE-Event-Headers. Die angegebenen Offsets sind absolute Offsets innerhalb des gesamten Events. Das XGE-Feld `length` gibt die Anzahl der 4-Byte-Einheiten nach den ersten 32 Bytes an.

### `ASYNC_ERROR`

Gesamtlänge: **60 Byte**; XGE `length = 7`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `device_xid`, 0 wenn nicht gerätebezogen |
| 36 | `CARD32` | `error_code` |
| 40 | `CARD32` | `origin` |
| 44 | `CARD64` | `submission_id`, 0 wenn nicht submissionbezogen |
| 52 | `XID` | `related_resource_xid`, 0 wenn nicht vorhanden |
| 56 | `CARD32` | `reserved`, MUST be zero |

### `DEVICE_LOST`

Gesamtlänge: **48 Byte**; XGE `length = 4`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `device_xid` |
| 36 | `CARD32` | `reason_code` |
| 40 | `CARD64` | `device_generation` |

### `DEVICE_STATUS_CHANGED`

Gesamtlänge: **48 Byte**; XGE `length = 4`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `physical_device_xid` |
| 36 | `CARD32` | `new_status` |
| 40 | `CARD32` | `reason_code` |
| 44 | `CARD32` | `reserved`, MUST be zero |

### `DEVICE_MEMORY_PRESSURE`

Gesamtlänge: **48 Byte**; XGE `length = 4`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `device_xid` |
| 36 | `CARD32` | `heap_index`, `UINT32_MAX` wenn kein bestimmter Heap gemeint ist |
| 40 | `CARD32` | `pressure_level` |
| 44 | `CARD32` | `reserved`, MUST be zero |

### `DEVICE_IDLE`

Gesamtlänge: **48 Byte**; XGE `length = 4`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `device_xid` |
| 36 | `CARD32` | `idle_reason` |
| 40 | `CARD64` | `device_generation` |

### `SUBMISSION_COMPLETE`

Gesamtlänge: **56 Byte**; XGE `length = 6`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `device_xid` |
| 36 | `CARD32` | `queue_family_index` |
| 40 | `CARD32` | `queue_index` |
| 44 | `CARD32` | `reserved`, MUST be zero |
| 48 | `CARD64` | `submission_id` |

### `SUBMISSION_FAILED`

Gesamtlänge: **56 Byte**; XGE `length = 6`.

| Offset | Typ | Feld |
|---:|---|---|
| 32 | `XID` | `device_xid` |
| 36 | `CARD32` | `queue_family_index` |
| 40 | `CARD32` | `queue_index` |
| 44 | `CARD32` | `failure_class` |
| 48 | `CARD64` | `submission_id` |

## 10.10 Zustellungs- und Identitätsregeln

1. `ASYNC_ERROR` und `DEVICE_LOST` werden an die betroffenen Clients zugestellt, unabhängig von ihren Event-Auswahlmasken.
2. Ein `SUBMISSION_COMPLETE`-Event darf erst nach erfolgreichem Abschluss der betreffenden Submission erzeugt werden. Die Annahme einer `QueueSubmit`-Anfrage allein genügt nicht.
3. Ein `SUBMISSION_FAILED`-Event darf nur für eine zuvor angenommene Submission erzeugt werden, deren Ausführung fehlgeschlagen ist.
4. Event-Referenzen auf Ressourcen verwenden deren öffentliche XIDs. Interne Objektidentitäten MUST unabhängig von XIDs verwaltet werden, damit verzögerte Arbeit und Events nicht irrtümlich auf neu angelegte Ressourcen mit wiederverwendeten XIDs verweisen.
5. Der Server MUST für dieselbe Submission höchstens einen terminalen Submission-Abschluss melden: entweder `SUBMISSION_COMPLETE` oder `SUBMISSION_FAILED`.
6. Ein Fehler kann sowohl ein obligatorisches `ASYNC_ERROR` als auch ein ausgewähltes `SUBMISSION_FAILED` auslösen, wenn beide Event-Bedeutungen zutreffen. Diese Events sind nicht als Duplikate zu behandeln.
7. Reservierte Felder in Event-Payloads MUST null sein.

