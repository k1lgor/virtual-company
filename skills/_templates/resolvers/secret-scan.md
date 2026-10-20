## 🔐 Secret Scanning

Any output that touches credentials requires an actual scan, not a visual read:

- Run the scanner: `<project_root>/scripts/security-sentinel.sh --text <path>`.
- Look for `AIza*`, `sk-*`, `ghp_*`, `AKIA*`, PEM private keys, and bearer tokens.
- Check env files, fixtures, and test data — real credentials leak there most often.
- A finding blocks completion until the secret is removed or proven to be a placeholder.

