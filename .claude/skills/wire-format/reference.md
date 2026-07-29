## X-server reply wire format — rpcbuf padding is done by the OS layer, not the handler

A recurring false-alarm trap when auditing reply handlers that build their payload with the
`x_rpcbuf_t` API (the post-migration style: `X_SEND_REPLY_WITH_RPCBUF` / `__write_reply_hdr_and_rpcbuf`
in `dix/request_priv.h`):

- The reply length is set to `header_units + x_rpcbuf_wsize_units(rpcbuf)`, where `wsize_units =
  (wpos+3)/4` **rounds up**. `WriteRpcbufToClient` then calls `dixWriteToClient(client, wpos, …)`.
- **`dixWriteToClient` (os/io.c) zero-pads *every* write up to a 4-byte unit** (`padBytes =
  padding_for_int32(count)` + `memset`; both the small-write/`FlushClient` path and the large
  `memcpy_and_flush` path). This is the classic "WriteToClient long-word-aligns things" behavior.
- **Therefore writing variable-length trailing data with the non-padding writers
  (`x_rpcbuf_write_CARD8s`, `x_rpcbuf_write_CARD16s`) is NOT a short-reply bug** — the bytes-on-wire
  always equal the declared `reply->length`. Do **not** report "final wpos isn't a multiple of 4" as
  a defect; it's padded by the OS output layer. (A June 2026 audit of ~45 such call-sites across 7
  extensions produced ~13 "bugs" that were all this false positive — the agents hadn't traced into
  `dixWriteToClient`.)

**The only real reply-corruption class here is *inter-element* misalignment**: when a reply writes
several variable-length elements back-to-back and a **per-element field declares the *padded* length
while the element itself is written *unpadded***. OS padding only pads the *end* of the whole buffer,
not the gaps *between* elements, so element N+1 is then read at the wrong offset. Two confirmed
instances:

- **`ProcXDGAQueryModes`** — each mode entry is `xXDGAModeInfo` (with `name_size = (size+3)&~3`,
  padded) followed by the name written `size` bytes (unpadded). Fixed in **PR #3173** by switching to
  `x_rpcbuf_write_string_0t_pad()` (pads each name). The sibling single-string handlers
  (`ProcXDGAOpenFramebuffer`, `xf86dri`, `appledri`, GetProperty, ListExtensions/Fonts, etc.) are
  **safe** — single trailing blob, OS-padded.
- **`x_rpcbuf_write_counted_string_pad(NULL)`** wrote *zero* bytes, but a counted string is a fixed
  wire element (CARD16 length + bytes + pad); an empty one is 4 bytes. Fixed in **PR #3195** to emit
  the empty counted string for NULL.

**Verification method that worked when the web spec was unreachable** (x.org PDF 403,
gitlab.freedesktop.org Anubis-blocked, the one-page HTML lacks Appendix D): use the **in-tree
round-trip contract** as the authority — the server's own *reader* for the same wire format
(`_GetCountedString` in `Xext/xkeyboard/xkb.c` unconditionally consumes a CARD16 length, advancing
`XkbPaddedSize(len+2)` → 4 bytes for an empty string) plus the *sizer* (`XkbSizeCountedString(NULL)
== 4`) define the contract precisely. Reader + sizer + writer must agree.
