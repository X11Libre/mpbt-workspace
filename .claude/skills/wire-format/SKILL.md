---
name: wire-format
description: "X-server reply wire format — rpcbuf padding is done by the OS layer, not the handler. Use when auditing reply handlers, investigating wire-format alignment issues, or reviewing changes to x_rpcbuf_t-based reply code."
---

# X-server reply wire format

When auditing reply handlers that build payload with `x_rpcbuf_t` (`X_SEND_REPLY_WITH_RPCBUF` /
`__write_reply_hdr_and_rpcbuf`), remember: **the OS output layer zero-pads every write to 4-byte
alignment** — the handler doesn't need to.

Full reference: **`reference.md`** in this skill's directory. This skill is the actionable checklist.

## Key facts

- Reply length is `header_units + x_rpcbuf_wsize_units(rpcbuf)` where `wsize_units = (wpos+3)/4` (rounds up).
- `dixWriteToClient` (os/io.c) zero-pads **every** write up to a 4-byte unit — both small-write/`FlushClient` and large `memcpy_and_flush` paths.
- **Do NOT report "final wpos isn't a multiple of 4" as a defect** — it's padded by the OS layer.

## The real bug class: inter-element misalignment

When a reply writes several variable-length elements back-to-back and a per-element field declares the **padded** length while the element itself is written **unpadded**, element N+1 is read at the wrong offset. OS padding only pads the *end* of the whole buffer, not gaps between elements.

Confirmed instances: `ProcXDGAQueryModes` (PR #3173), `x_rpcbuf_write_counted_string_pad(NULL)` (PR #3195).

## Verification method

Use the in-tree round-trip contract: the server's own *reader* (`_GetCountedString`) + *sizer* (`XkbSizeCountedString`) + *writer* must agree.
