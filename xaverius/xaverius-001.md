# XAverius – Protokollentwurf und bisheriger Stand

**Status:** Arbeitsentwurf, keine normative Spezifikation  
**Stand:** 19. Oktober 2026  
**Zweck:** Sicherung des bisherigen Architektur- und Protokolldesigns

## 1. Ziel und Architektur

XAverius ist eine geplante X11-Erweiterung für netzwerktransparentes Vulkan. Vulkan-Aufrufe des Clients werden über das bestehende X11-Verbindungsprotokoll an einen Server übertragen, der die entsprechenden Vulkan-Operationen ausführt.

Grundprinzipien:

- XAverius verwendet normale X11-Requests, Replies, Errors und bei Bedarf Events.
- Es wird kein separates XAverius-Socket benötigt.
- Der Server verarbeitet Requests eines Clients in Empfangsreihenfolge.
- Request-Reihenfolge ist nicht gleichbedeutend mit GPU-Abschluss.
- XIDs folgen den X11-Regeln und identifizieren serverseitig verwaltete Vulkan-Ressourcen.
- Das Protokoll serialisiert Felder explizit; native C-Strukturen werden nicht unverändert übertragen.

## 2. Serialisierung und Alignment

- Keine nativen Pointer, `size_t`-Felder, compilerabhängigen Padding-Bytes oder ungeprüften `pNext`-Pointer auf dem Draht.
- Strukturen werden Feld für Feld mit explizit festgelegten Größen und Bedeutungen serialisiert.
- Variable Datenbereiche werden durch die Request-Länge und/oder explizite Längenfelder bestimmt.
- XAverius-Transferdaten sollen an 4-Byte-Grenzen ausgerichtet sein.
- Vulkan-Felder, deren Semantik in Bytes definiert ist, behalten ihre Byte-Semantik. Sie werden nicht stillschweigend als 32-Bit-Wortanzahlen interpretiert.
- Bei Strings ist die tatsächliche Länge die Anzahl der Bytes ohne abschließendes NUL, sofern ein NUL nicht ausdrücklich Bestandteil des Feldes ist. Padding zählt nicht zur tatsächlichen Länge.
- Die Byte-Reihenfolge folgt der Byte-Reihenfolge der jeweiligen X11-Verbindung.

## 3. Opcode-Namespace

### 3.1 X11-Header

Der normale X11-Request-Header ist 4 Byte groß:

| Feld | Größe | Bedeutung |
|---|---:|---|
| Major Opcode | 8 Bit | Vom X-Server zugewiesener Opcode für XAverius |
| Minor Opcode / Datenbyte | 8 Bit | XAverius-Befehlsfamilie |
| Length | 16 Bit | Request-Länge in 4-Byte-Einheiten; bei BigRequests gilt das erweiterte X11-Format |

XAverius erhält normalerweise **einen** zugewiesenen Major Opcode. Es stehen daher nicht 256 XAverius-Major-Opcodes zur Verfügung. Die 256 Werte des X11-Minor-Opcode-Felds bilden die erste Ebene des XAverius-Namespaces.

### 3.2 Matrix aus Familien und Subopcodes

Vorgesehenes Schema:

- X11 Major Opcode: XAverius
- X11 Minor Opcode (8 Bit): Befehlsfamilie
- XAverius Subopcode (8 Bit): konkrete Operation innerhalb der Familie
- XAverius Flags (8 Bit): operationsspezifische Optionen

Damit sind theoretisch bis zu 256 Familien mit jeweils bis zu 256 Subopcodes möglich.

### 3.3 Gemeinsamer XAverius-Request-Header

Aktueller Vorschlag direkt nach dem 4-Byte-X11-Header:

| Feld | Größe | Status |
|---|---:|---|
| `subopcode` | 8 Bit | Vorgesehen |
| `flags` | 8 Bit | Vorgesehen |
| `reserved` | 16 Bit | Vorgesehen; in Version 0.1 muss der Wert null sein |

```c
CARD8  subopcode;
CARD8  flags;
CARD16 reserved;   /* Must be zero in protocol v0.1 */
```

Dieser Header hält die nachfolgenden Payload-Felder an einer 4-Byte-Grenze. Er ist ein Strukturvorschlag, noch keine endgültige normative Festlegung.

Für Chunk-Uploads wurde zusätzlich ein spezielles Headerformat erwogen. Die endgültige Beziehung zwischen dem gemeinsamen Header und speziellen Request-Headern ist noch offen.

### 3.4 Beispielhafte Familienaufteilung

Nur Vorschläge; Werte sind noch nicht endgültig vergeben:

| Familienwert | Familie |
|---:|---|
| 0 | XAverius-Protokoll und Abfragen |
| 1 | Geräte und Queues |
| 2 | Speicher |
| 3 | Buffer und Image |
| 4 | Shader und Pipelines |
| 5 | Command Buffers und Command Recording |
| 6 | Synchronisation |
| 7 | Submission und Präsentation |
| 8 | Queries, Debugging und optionale Funktionen |

Opcode-Werte sollen zentral und dauerhaft definiert werden, idealerweise in einer maschinenlesbaren Quelle, aus der Client- und Server-Header generiert werden.

## 4. Bisher besprochene Requests

Die folgende Liste ist keine vollständige Liste aller Vulkan-Befehle. Bei den meisten Requests sind die endgültigen Wire-Layouts noch offen.

### 4.1 Protokoll und Capabilities

| Request | Zweck | Status |
|---|---|---|
| `QueryVersion` | XAverius-Protokollversion, grundlegende Limits und Feature-Bits abfragen | Besprochen; Payload und Reply offen |
| `QueryVulkanCapabilities` | Vulkan-Unterstützung und Drawable-Kompatibilität abfragen | Besprochen; Payload und Reply offen |
| `Sync` / Synchronisationsbarriere | Sicherstellen, dass vorherige Requests serverseitig verarbeitet wurden | Semantik besprochen; Name und Layout offen |

`QueryVulkanCapabilities` nimmt eine Drawable-XID entgegen. Der Server bestimmt den Ressourcentyp selbst, beispielsweise Window oder Pixmap. Nicht jede Pixmap muss Vulkan-presentable sein. Die Unterstützung kann von Screen, Gerät und Treiber abhängen.

Capability-Ebenen:

1. XAverius-Protokollunterstützung des Servers
2. Vulkan-Geräte- und Feature-Unterstützung
3. Kompatibilität eines konkreten X11-Drawables

Vulkan-Extension-Namen werden als Strings übertragen, nicht als X11 Atoms. Vorgeschlagen ist eine längenpräfixierte Darstellung mit Byte-Länge ohne NUL und 4-Byte-Padding. Namen sind case-sensitive.

### 4.2 Ressourcen und Speicher

| Request | Bisher besprochene Parameter / Funktion |
|---|---|
| `CreateBuffer` | Buffer-XID, Größe, Usage, Create-Flags |
| `DestroyBuffer` | Buffer-XID |
| `AllocateMemory` | Memory-XID, Größe, Memory-Typ, Flags |
| `FreeMemory` | Memory-XID |
| `BindBufferMemory` | Buffer-XID, Memory-XID, Offset |
| `ReadBuffer` | Buffer-XID, Offset, Länge; Reply enthält Daten |
| `WriteBuffer` | Buffer-XID, Offset, Daten |

Die konkreten Feldgrößen, Feldreihenfolgen und Replies dieser Requests sind noch nicht vollständig spezifiziert.

Sichere Bounds-Prüfung für Bereichsoperationen:

```c
offset <= buffer_size && size <= buffer_size - offset
```

### 4.3 Shader und Pipelines

| Request | Bisher besprochene Parameter / Funktion |
|---|---|
| `CreateShaderModule` | Shader-XID, Vulkan-Create-Flags, SPIR-V-Payload |
| `DestroyShaderModule` | Shader-XID |
| `CreateGraphicsPipelines` | Pipeline- und Create-Info-Daten |

Für `CreateShaderModule` ist für Version 0.1 vorgesehen, `pNext = NULL` zu verwenden.

Weitere Festlegungen und Einschränkungen:

- Allocator-Callbacks können nicht über die Verbindung übertragen werden.
- Das `sType` ist durch den Request-Typ implizit.
- Die Create-Flags sind ein 32-Bit-Vulkan-Feld.
- Gültige Flag-Werte müssen geprüft werden; der übliche Wert ist null.
- Vulkan-Strukturen mit `pNext` müssen bei späterer Unterstützung explizit serialisiert werden.
- Validierungs-Extensions wurden vorerst aus dem Anfangsumfang ausgeklammert.

### 4.4 Command Buffers, Synchronisation und Submission

Folgende Requests wurden als vorgesehene Bestandteile genannt; konkrete Wire-Layouts sind noch offen:

- `CreateCommandPool`, `DestroyCommandPool`
- `AllocateCommandBuffers`, `FreeCommandBuffers`
- `BeginCommandBuffer`, `EndCommandBuffer`, `ResetCommandBuffer`
- `Cmd...`-Requests für aufgezeichnete Vulkan-Befehle, etwa Draws, Dispatches und Kopien
- `CreateFence`, `DestroyFence`, `GetFenceStatus`, `WaitForFences`, `ResetFences`
- `CreateSemaphore`, `DestroySemaphore`
- `QueueSubmit`
- `QueueWaitIdle`, `DeviceWaitIdle`

`QueueSubmit` wurde als wichtiger Request mit Submit-Informationen und Synchronisationsdaten besprochen. Die genaue Behandlung von Semaphoren, Fences und Ergebnissen muss noch normiert werden.

## 5. Chunk-Uploads

Chunk-Uploads wurden insbesondere für große Payloads wie SPIR-V-Code besprochen.

### 5.1 Vorgesehener Ablauf

1. Der Client sendet den ersten `CreateShaderModule`-Request mit einer neuen XID.
2. Der Server legt eine Ressource im Zustand `UPLOADING` an.
3. Weitere Chunks verwenden dieselbe XID und denselben Request-Typ.
4. Ein `FINAL`-Flag kennzeichnet den letzten Chunk.
5. Nach vollständigem Empfang versucht der Server, das Vulkan-Objekt zu erstellen.
6. Der Zustand wechselt zu `READY` oder `FAILED`.
7. Ein `FAILED`-Objekt bleibt bis zur expliziten Zerstörung bestehen.
8. Beim Disconnect werden die Vulkan-Ressourcen dieses Clients freigegeben.

Zustandsmodell:

```text
UPLOADING -> READY
UPLOADING -> FAILED
```

Ein nicht abgeschlossener Upload wird durch explizites `Destroy` entfernt. Ein fehlgeschlagener Chunk soll voraussichtlich den Upload in `FAILED` überführen; die genaue Fehlerbehandlung ist noch abschließend festzulegen.

### 5.2 Chunk-Header – bisheriger Vorschlag

Ein spezieller 8-Byte-Chunk-Header wurde vorgeschlagen:

```c
struct XAveriusChunkHeader {
    CARD32 xid;
    CARD32 flags;  /* bit 0 = FINAL; other bits reserved */
};
```

Dieser Vorschlag ist noch keine endgültige Entscheidung. Alternativ könnte der allgemeine 4-Byte-Header beibehalten und die XID im operationsspezifischen Payload geführt werden. Es muss entschieden werden, ob der Chunk-Header den allgemeinen XAverius-Header ergänzt oder bei Chunk-Requests an dessen Stelle tritt.

### 5.3 Chunk-Größen und Shader-Payload

- `chunk_words` ist nicht erforderlich; die Chunk-Payload-Größe ergibt sich aus der X11-Request-Länge minus festen Header- und Metadatenfeldern.
- `total_words` ist nicht erforderlich; die Gesamtlänge ergibt sich aus der Summe der Chunk-Payloads.
- `FINAL` markiert das Ende des Uploads.
- Für `CreateShaderModule` soll `codeSize` auf dem Draht entfallen; die SPIR-V-Länge wird aus den empfangenen Chunks ermittelt.
- Im ersten Shader-Chunk folgen auf die Headerfelder die 32-Bit-Create-Flags und anschließend SPIR-V-Daten. In Fortsetzungs-Chunks folgen nur SPIR-V-Daten.
- Die Erkennung des ersten bzw. eines folgenden Chunks erfolgt anhand des serverseitigen Ressourcenstatus.
- Die Request-Länge und die Grenzen des Transportpakets müssen geprüft werden.
- Ein Vergleich der SPIR-V-Gesamtlänge mit einem separat übertragenen `codeSize` ist in diesem Design nicht vorgesehen.

Weitere mögliche Kandidaten für Chunk-Uploads sind `CreateShaderEXT`-Code und initiale `CreatePipelineCache`-Daten. Pipeline-Create-Infos sind oft komplexe strukturierte Metadaten und wurden nicht als primärer Chunk-Upload-Kandidat festgelegt.

## 6. Request-Reihenfolge, Pipelining und GPU-Abschluss

- Requests eines Clients werden serverseitig in Empfangsreihenfolge verarbeitet.
- Der Client darf Requests pipelinen; es ist kein Roundtrip nach jedem Request erforderlich.
- Das Scheitern eines Requests bricht spätere Requests nicht automatisch ab.
- Nachfolgende Requests, die eine nicht erfolgreich erstellte Ressource verwenden, können eigene Fehler auslösen.
- Eine Request-Barriere bestätigt die Verarbeitung vorangegangener Requests und ermöglicht es, deren X11-Errors zu empfangen. Sie wartet **nicht** automatisch auf GPU-Abschluss.
- GPU-Abhängigkeiten und Completion werden durch Vulkan-Synchronisationsmechanismen wie Fences, Semaphores und explizite Waits geregelt.
- Operationen, deren Vulkan-Semantik ein synchrones `VkResult` oder Ausgabedaten erfordert, brauchen einen entsprechenden Reply-/Ergebnisweg. Request-Pipelining bleibt trotzdem möglich.

## 7. Fehlerbehandlung

### 7.1 Grundregeln

- Protokollfehler verwenden normale X11-Error-Pakete und die zugehörigen X11-Request-Sequenznummern.
- Für gewöhnliche Request-Fehler werden keine zusätzlichen X-Events erzeugt.
- Der Server verwendet vorhandene X11-Error-Codes, wo sie semantisch passen, beispielsweise `BadRequest`, `BadValue`, `BadIDChoice`, `BadDrawable` oder `BadAlloc`.
- Eigene XAverius-X11-Error-Codes sollen möglichst vermieden werden.
- Asynchrone Events sind für tatsächlich unabhängige oder später auftretende Ereignisse vorgesehen, etwa Device Lost.

### 7.2 Vulkan-Ergebnisse und X11-Errors

`VkResult`-Werte haben nicht alle eine semantisch genaue Entsprechung in X11-Error-Codes. `VK_ERROR_OUT_OF_HOST_MEMORY` und `VK_ERROR_OUT_OF_DEVICE_MEMORY` wurden als mögliche Fälle für `BadAlloc` besprochen. Die Zuordnung muss noch normativ festgelegt werden.

Ein Entwurf sieht vor, die standardisierte 32-Byte-X11-Error-Struktur beizubehalten und in einem dafür geeigneten XAverius-Feld den exakten 32-Bit-`VkResult` zu übertragen. Ein definierter Sentinel würde anzeigen, dass kein Vulkan-Ergebnis vorliegt.

Die genaue Bytebelegung muss gegen die X11-Core-Error-Struktur und Erweiterungskonventionen geprüft werden. Das X11-`errorCode`-Feld darf nicht für einen `VkResult` zweckentfremdet werden.

## 8. Replies

X11-Replies verwenden das standardisierte X11-Reply-Format. Der übliche Reply hat einen 32-Byte-Festteil und kann variable Zusatzdaten enthalten. Die Zusatzdatenlänge wird in 4-Byte-Einheiten angegeben.

Vorgesehene Reply-Inhalte:

- Protokollversion und Basislimits
- Vulkan-Capabilities und Extension-Namen
- Exakter `VkResult`
- Zurückgegebene XIDs oder andere Vulkan-Ausgabewerte
- Daten von `ReadBuffer` und anderen Leseoperationen

Die konkreten Feldbelegungen für XAverius-Replies sind noch offen. Der allgemeine XAverius-Request-Header wird nicht automatisch in Replies wiederverwendet.

## 9. Präsentation und X11-Drawables

Das Ziel umfasst Rendering in X11-Windows und die Untersuchung von Pixmaps sowie gegebenenfalls X Render Pictures.

Zu beachten:

- Nicht alle Pixmaps sind notwendigerweise Vulkan-presentable.
- Ein Capability-Query muss die konkrete Drawable-Kompatibilität berücksichtigen.
- Unterstützung kann von Screen, GPU, Gerät und Treiber abhängen.
- Ein X Render Picture ist nicht dasselbe wie ein RandR-Ausgang bzw. Display-Output. Diese Unterscheidung muss bei der späteren Present-/Rendering-Spezifikation erhalten bleiben.

## 10. Statusübersicht

### Vereinbarte bzw. stark bevorzugte Grundsätze

- XAverius nutzt die normale X11-Verbindung.
- X11 weist XAverius einen Major Opcode zu.
- Das X11-Minor-Opcode-Feld dient als Familiennummer.
- Ein zusätzlicher 8-Bit-Subopcode und 8-Bit-Flags sind vorgesehen.
- Payload-Felder werden explizit serialisiert und 4-Byte-Alignment wird angestrebt.
- Vulkan-Extension-Namen werden als Strings, nicht als Atoms, übertragen.
- `QueryVersion` und `QueryVulkanCapabilities` sind vorgesehen.
- Request-Verarbeitung und GPU-Completion sind getrennte Konzepte.
- Chunk-Uploads verwenden wiederholte Requests mit derselben XID und einem `FINAL`-Flag.
- `CreateShaderModule` soll im v0.1-Entwurf ohne `pNext` auskommen und die Gesamtlänge aus den Chunks ableiten.
- Normale Request-Fehler nutzen X11-Errors; eigene Error-Codes sollen möglichst vermieden werden.

### Noch offen

1. Finale Zuordnung aller Familien-Minor-Opcodes und Subopcodes.
2. Ob Chunk-Requests den allgemeinen XAverius-Header ergänzen oder ein alternatives Headerformat verwenden.
3. Vollständige Byte-Layouts aller Requests und Replies.
4. Exakte Belegung der 32-Byte-X11-Error-Struktur für XAverius- und Vulkan-Fehler.
5. Normative Tabelle der Vulkan-Result-to-X11-Error-Zuordnungen.
6. Genaue Semantik und Wire-Formate für Command Recording, `QueueSubmit`, Present und Synchronisation.
7. Detaillierte Regeln für `FAILED`-Ressourcen und Fehler während eines Chunk-Uploads.
8. Exakte Capability-Antwortfelder und Gründe für fehlende Drawable-/Feature-Unterstützung.
9. Welche Vulkan-Befehle serverseitig abgebildet werden und welche lokal im Client bleiben.

## 11. Beispiel für eine geplante Request-Familie

Nur illustrativ; Werte sind nicht endgültig zugewiesen:

| Familien-Minor | Subopcode | Operation |
|---:|---:|---|
| 2 (`Memory`) | 0 | `AllocateMemory` |
| 2 (`Memory`) | 1 | `FreeMemory` |
| 2 (`Memory`) | 2 | `BindBufferMemory` |
| 2 (`Memory`) | 3 | `WriteMemory` |
| 2 (`Memory`) | 4 | `ReadMemory` |

Die Grundidee ist, die Befehlsfamilie über den X11-Minor-Opcode und die konkrete Operation über den XAverius-Subopcode auszuwählen. Jede Operation definiert ihr eigenes Payload-Layout. Bei stark unterschiedlichen Payloads werden bevorzugt separate Subopcodes verwendet; Flags sollen nicht unbemerkt die Struktur eines Payloads ändern.

---

**Hinweis:** Dieses Dokument sichert den bisher diskutierten Stand. Vorschläge, Beispielwerte und offene Fragen sind ausdrücklich als solche markiert und sollten vor einer Implementierung in eine normative Spezifikation überführt werden.
