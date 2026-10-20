# XAverius Protocol Specification

**Status:** Working Draft  
**Protocol version:** 0.1

## 1. Grundstruktur des Protokolls

### 1.1. Geltungsbereich

XAverius ist eine X11-Extension zur Bereitstellung von Vulkan-Funktionalität über eine bestehende X11-Verbindung.

Die grundlegenden Regeln des X11-Protokolls gelten unverändert, sofern diese Spezifikation keine ausdrückliche Ergänzung oder Abweichung definiert. Dies betrifft insbesondere den Aufbau von Requests, Replies und Errors, die Byte-Reihenfolge, die grundlegenden Protokolltypen, die Ausrichtung von Requests, die Sequenznummern sowie die Regeln für XIDs.

XAverius definiert keinen zusätzlichen Transportkanal.

### 1.2. XAverius-Request-Struktur

XAverius verwendet den von X11 vorgesehenen Request-Header. Der vom X11-Server zugewiesene Major Opcode identifiziert die Extension.

Der Minor Opcode wird von XAverius als **Command-Family-Kennung** verwendet. Innerhalb einer Command Family identifiziert ein XAverius-Subopcode den konkreten Request-Typ.

Die Kombination aus Minor Opcode und Subopcode bestimmt somit den XAverius-Request-Typ.

### 1.3. Gemeinsamer XAverius-Header

Requests, die den gemeinsamen XAverius-Header verwenden, enthalten unmittelbar nach dem X11-Request-Header die folgenden vier Bytes:

| Feld | Typ | Bedeutung |
|---|---|---|
| `subopcode` | `CARD8` | Kennung des Request-Typs innerhalb der Command Family |
| `flags` | `CARD8` | Request-spezifische Flags |
| `reserved` | `CARD16` | In Version 0.1 reserviert; muss null sein |

Der gemeinsame Header belegt die Bytes 4 bis 7 des Requests. Das request-spezifische Payload beginnt bei Byte-Offset 8.

Ein Request, der diesen Header nicht verwendet, muss dies in seiner Definition ausdrücklich festlegen.

Nicht definierte Flag-Bits müssen in Version 0.1 null sein. Die zulässigen Flags und ihre Semantik werden für jeden Request-Typ einzeln definiert.

Unterschiedliche Payload-Layouts werden grundsätzlich durch unterschiedliche Subopcodes gekennzeichnet. Flags dürfen nicht ohne ausdrückliche Definition die Struktur eines Payloads verändern.

### 1.4. Command Families und Kennungsräume

Der Minor Opcode stellt bis zu 256 Kennungen für Command Families bereit. Innerhalb jeder Family stellt `subopcode` bis zu 256 Kennungen für Request-Typen bereit.

Die folgende Zuordnung ist vorläufig:

| Minor Opcode | Command Family | Zuständigkeit |
|---:|---|---|
| 0 | Protocol | Versions- und Fähigkeitsabfragen |
| 1 | Devices and Queues | Geräte und Queues |
| 2 | Memory | Speicherverwaltung |
| 3 | Buffers and Images | Buffer- und Image-Ressourcen |
| 4 | Shaders and Pipelines | Shader-Module und Pipelines |
| 5 | Commands | Command Pools, Command Buffers und Command Streams |
| 6 | Synchronization | Fences, Semaphores und Synchronisationsoperationen |
| 7 | Submission and Presentation | Queue-Submission und Presentation |
| 8 | Queries and Optional Features | Zusätzliche Abfragen und optionale Funktionalität |

Die endgültige Vergabe der Kennungen wird zentral dokumentiert. Bereits definierte Kennungen dürfen nicht ohne eine ausdrücklich festgelegte Kompatibilitätsregel mit einer anderen Bedeutung wiederverwendet werden.

### 1.5. XAverius-spezifische Serialisierungsregeln

Die allgemeinen Regeln zur Byte-Reihenfolge und Ausrichtung richten sich nach der X11-Protokollspezifikation.

Darüber hinaus gelten für XAverius folgende Festlegungen:

1. Native Speicherlayouts von C- oder Vulkan-Strukturen sind kein Wire-Format.
2. Zeiger, native Funktionszeiger, `size_t` und compilerabhängiges Padding dürfen nicht als solche übertragen werden.
3. Jedes XAverius-spezifische Feld muss in der jeweiligen Request- oder Command-Definition mit Typ, Bedeutung und Länge beschrieben werden.
4. Variable Datenfelder müssen eine eindeutig bestimmbare semantische Länge besitzen. Padding zählt nicht zur semantischen Länge.
5. Arrays, verschachtelte Strukturen und optionale Felder müssen durch das jeweilige Wire-Schema eindeutig dekodierbar sein.
6. Längenfelder müssen ihre Einheit ausdrücklich angeben, beispielsweise Bytes, Elemente oder Vier-Byte-Wörter.
7. Vulkan-Strukturen einschließlich optionaler Erweiterungsstrukturen dürfen nur übertragen werden, wenn für sie ein ausdrückliches Wire-Schema definiert ist.

Die Regeln für das X11-Request-Längenfeld und gegebenenfalls `BIG-REQUESTS` ergeben sich aus der X11-Protokollspezifikation. XAverius-spezifische Längenfelder innerhalb eines Payloads unterliegen zusätzlich den Definitionen des jeweiligen Request-Typs.

### 1.6. XAverius-Ressourcentypen

XAverius verwendet die X11-Regeln für Resource IDs (XIDs). Die folgenden Namen bezeichnen die vorgesehenen XAverius-Ressourcentypen:

- `XAV_COMMAND_POOL`
- `XAV_COMMAND_BUFFER`
- `XAV_BUFFER`
- `XAV_DEVICE_MEMORY`
- `XAV_SHADER_MODULE`
- `XAV_PIPELINE`
- `XAV_FENCE`
- `XAV_SEMAPHORE`

Diese Bezeichnungen dienen der eindeutigen Beschreibung der Protokollfelder. Sie ändern weder die Größe noch die Vergaberegeln der zugrunde liegenden XIDs.

Die Zuordnung von XIDs zu konkreten Ressourcen, die Regeln für Ressourcenerzeugung und -zerstörung sowie die Lebensdauer zugrunde liegender Vulkan-Objekte werden in Kapitel 3 definiert.

### 1.7. Versionierung und Erweiterbarkeit

Die unterstützte XAverius-Protokollversion wird durch den in Kapitel 2 definierten Request `QueryVersion` ermittelt.

Command Families, Subopcodes und Command-IDs werden zentral verwaltet. Reservierte und nicht unterstützte Kennungen müssen eindeutig behandelt werden.

Neue Request-Typen und optionale Funktionen müssen so eingeführt werden, dass die Bedeutung bereits definierter Kennungen und Payload-Schemata erhalten bleibt. Weitergehende Kompatibilitätsregeln werden in Kapitel 9 festgelegt.

---

## Arbeitsnotizen zu Kapitel 1 — nicht normativ

- Prüfen, ob der gemeinsame XAverius-Header für ausnahmslos alle Request-Typen verbindlich sein soll. Falls ja, kann die Ausnahmeformulierung in Abschnitt 1.3 entfallen.
- Endgültige Vergabe und Dokumentation der Minor Opcodes für Command Families bestätigen.
- Das Präfix `XAV_` für Ressourcentypen bestätigen.
- Prüfen, ob die Regeln zur Serialisierung in Abschnitt 1.5 vollständig auf XAverius-spezifische Einschränkungen begrenzt sind und keine X11-Grundregeln wiederholen.
- Vor Veröffentlichung sicherstellen, dass die Verweise auf die X11-Protokollspezifikation und die Abschnitte der XAverius-Spezifikation eindeutig sind.

Dieses Arbeitsnotiz-Kapitel ist vor einer Veröffentlichung der Spezifikation zu entfernen.
