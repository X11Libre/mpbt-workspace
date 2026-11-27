import tempfile
import unittest
from pathlib import Path

from validate_message import ValidationError, validate


class ValidateMessageTests(unittest.TestCase):
    def write_message(self, text: str, name: str = "w0-test.md") -> Path:
        directory = Path(tempfile.mkdtemp())
        path = directory / name
        path.write_text(text, encoding="utf-8")
        return path

    def valid(self, subject: str = '"A safe subject: with colon"') -> str:
        return f'''---
id: "w0-test"
from: "ChatGPT"
to: "Nautilus"
subject: {subject}
type: "message"
reply_to: ""
created: "2026-11-27T12:00:00Z"
---
A non-empty body.
'''

    def test_accepts_quoted_colon_in_subject(self):
        fields = validate(self.write_message(self.valid()), "Nautilus")
        self.assertEqual(fields["subject"], "A safe subject: with colon")

    def test_rejects_unquoted_colon(self):
        with self.assertRaisesRegex(ValidationError, "JSON double-quoted"):
            validate(self.write_message(self.valid("A broken subject: with colon")))

    def test_rejects_wrong_recipient(self):
        with self.assertRaisesRegex(ValidationError, "does not match"):
            validate(self.write_message(self.valid()), "Enterprise")

    def test_rejects_duplicate_keys(self):
        text = self.valid().replace('to: "Nautilus"', 'to: "Nautilus"\nto: "Enterprise"')
        with self.assertRaisesRegex(ValidationError, "duplicate key"):
            validate(self.write_message(text))

    def test_rejects_empty_body(self):
        text = self.valid().split("---\n", 2)
        empty = text[0] + "---\n" + text[1] + "---\n"
        with self.assertRaisesRegex(ValidationError, "body must not be empty"):
            validate(self.write_message(empty))

    def test_rejects_filename_id_mismatch(self):
        with self.assertRaisesRegex(ValidationError, "filename must be exactly"):
            validate(self.write_message(self.valid(), "wrong-name.md"))


if __name__ == "__main__":
    unittest.main()
