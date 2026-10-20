## ✏️ Edit Integrity

- Re-read the file immediately before every edit.
- Re-read it after the edit to confirm the change applied.
- The Edit tool fails silently when `old_string` does not match. A failed match is a stale-context signal, not a tool bug — re-read and retry.
- Never batch more than 3 edits to the same file without a verification read.

