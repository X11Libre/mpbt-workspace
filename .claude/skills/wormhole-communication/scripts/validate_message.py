#!/usr/bin/env python3
"""Validate a Wormhole Maildir message before publishing it.

The accepted front matter is deliberately a strict YAML subset: every value is
a JSON double-quoted string. JSON strings are valid YAML scalars, and this
avoids YAML's ambiguous plain-scalar rules (notably unquoted colons).
Only Python's standard library is required.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

KEY_RE = re.compile(r"^[a-z][a-z0-9_]*$")
TOKEN_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
REQUIRED = {"id", "from", "to", "subject", "type", "created"}


class ValidationError(ValueError):
    pass


def validate(path: Path, recipient: str | None = None) -> dict[str, str]:
    try:
        raw = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise ValidationError(f"cannot read UTF-8 message: {exc}") from exc

    lines = raw.splitlines()
    if not lines or lines[0] != "---":
        raise ValidationError("file must start with an exact YAML front-matter delimiter '---'")

    try:
        end = lines.index("---", 1)
    except ValueError as exc:
        raise ValidationError("missing closing YAML front-matter delimiter '---'") from exc

    fields: dict[str, str] = {}
    for number, line in enumerate(lines[1:end], start=2):
        if not line or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise ValidationError(f"line {number}: expected key: JSON-quoted-string")
        key, value = line.split(":", 1)
        key = key.strip()
        if not KEY_RE.fullmatch(key):
            raise ValidationError(f"line {number}: invalid key {key!r}")
        if key in fields:
            raise ValidationError(f"line {number}: duplicate key {key!r}")
        value = value.strip()
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError as exc:
            raise ValidationError(
                f"line {number}: value for {key!r} must be a JSON double-quoted string; {exc.msg}"
            ) from exc
        if not isinstance(parsed, str):
            raise ValidationError(f"line {number}: value for {key!r} must be a string")
        fields[key] = parsed

    missing = sorted(REQUIRED - fields.keys())
    if missing:
        raise ValidationError("missing required fields: " + ", ".join(missing))

    for key in ("id", "from", "to"):
        if not TOKEN_RE.fullmatch(fields[key]):
            raise ValidationError(f"{key} must match [A-Za-z0-9][A-Za-z0-9._-]*")

    if path.name != fields["id"] + ".md":
        raise ValidationError(f"filename must be exactly {fields['id']}.md")
    if recipient is None:
        raise ValidationError("--recipient is required")
    if fields["to"] != recipient:
        raise ValidationError(f"to={fields['to']!r} does not match recipient mailbox {recipient!r}")
    if path.parts[-4:-1] != ("mail", recipient, "new"):
        raise ValidationError(f"destination must be mail/{recipient}/new/<message-id>.md")

    try:
        created = datetime.strptime(fields["created"], "%Y-%m-%dT%H:%M:%SZ")
    except ValueError as exc:
        raise ValidationError("created must be UTC RFC3339 in YYYY-MM-DDTHH:MM:SSZ form") from exc
    if created.strftime("%Y-%m-%dT%H:%M:%SZ") != fields["created"]:
        raise ValidationError("created must be canonical UTC RFC3339")

    if end == len(lines) - 1 or not "\n".join(lines[end + 1:]).strip():
        raise ValidationError("message body must not be empty")

    return fields


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("message", type=Path, help="path to <message-id>.md")
    parser.add_argument("--recipient", required=True, help="expected recipient/mailbox directory")
    args = parser.parse_args()
    try:
        fields = validate(args.message, args.recipient)
    except ValidationError as exc:
        print(f"INVALID: {exc}", file=sys.stderr)
        return 1
    print(f"VALID: {fields['id']} -> {fields['to']} ({fields['type']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
