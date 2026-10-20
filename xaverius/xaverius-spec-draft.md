XAVERIUS X11 PROTOCOL EXTENSION
==============================

Cardinal types
--------------

XAVERIUS_CMD_POOL = XID
XAVERIUS_CMD_BUF = XID
XAVERIUS_BUFFER_XID = XID
XAVERIUS_DEVICE_MEMORY = XID
XAVERIUS_SHADER = XID
XAVERIUS_FENCE = XID
XAVERIUS_SEMAPHORE = XID

Generic xaverius request header
------------------------------

All Xaverius requests following the same common request scheme.
Optional payloads are depending on actual commands / opcodes.

| offset | type   | description                   |
| 0      | CARD8  | X11 extensiond ID (=XAVERIUS) |
| 1      | CARD8  | xaverus command family        |
| 2      | CARD16 | packet length (in units)      |
| 4      | CARD8  | xaverus command opcode        |
| 5      | CARD8  | command specific flags        |
| 6      | CARD16 | command specific reserved     |
| 8      | ....   | optional payload              |

Command header
--------------

When command streams are submitted, they encoded as a series of
packetes consisting of command header + payload:

| offset | type   | description          |
| 0      | CARD16 | packet size in units |
| 2      | CARD16 | command opcode       |
| 4      | .....  | command payload      |

The payload is always padded to to 4-byte-units.
