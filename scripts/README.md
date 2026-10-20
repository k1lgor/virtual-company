# 🔨 Virtual Company Verification Scripts

Mechanical enforcement scripts for all hard gates in the Virtual Company skill system. These scripts turn text-based gates into executable checks.

## Scripts

### 1. `validate-skill.sh` — Skill Quality Validator

Checks if a SKILL.md has all required sections and returns a quality score (1-10).

```bash
./scripts/validate-skill.sh ./skills/02-bug-hunter/SKILL.md
```

**Checks:** Iron Law, HARD-GATE, Failure Modes, Red Flags, Verification, Decision Tree, Collaborative Links, no placeholders, examples, code blocks.
**Exit:** 0 if score ≥ 9/10, 1 otherwise.

---

### 2. `security-sentinel.sh` — Enhanced Secret Scanner

Scans files for leaked secrets and credentials across 18+ patterns.

```bash
./scripts/security-sentinel.sh --text src/ config/
./scripts/security-sentinel.sh --json --severity HIGH .
echo "key=sk-abc123" | ./scripts/security-sentinel.sh --text
```

**Patterns:** Google API keys, OpenAI, GitHub tokens, AWS keys, private keys, JWT, Slack, Stripe, Twilio, SendGRID, Heroku, npm.
**Custom patterns:** Add regexes to `.secret-patterns` file (one per line, `#` comments).
**Exit:** 0 if clean, 1 if secrets found.

---

### 3. `verify-gate.sh` — Gate Verification Runner

Run any command as a verification gate and optionally log the result.

```bash
./scripts/verify-gate.sh --gate-name "lint" --command "eslint src/" --log gates.tsv
./scripts/verify-gate.sh --gate-name "type-check" --command "tsc --noEmit"
```

**Output:** Colored PASS/FAIL with command evidence (truncated to 500 chars).
**Log format:** `timestamp | gate_name | status | exit_code | duration_ms | output_summary`
**Exit:** Same as the verification command's exit code.

---

### 4. `coverage-gate.sh` — Test Coverage Gate

Run tests and enforce coverage meets a threshold.

```bash
./scripts/coverage-gate.sh --threshold 80
./scripts/coverage-gate.sh --command "pytest --cov --cov-report=term-missing" --threshold 90
./scripts/coverage-gate.sh --reporter json --threshold 85
```

**Auto-detect:** Node (package.json), Python (requirements.txt), Go (go.mod).
**Output:** PASS/FAIL with actual coverage vs threshold.
**Exit:** 0 if coverage ≥ threshold, 1 otherwise.

---

### 5. `audit-deps.sh` — Dependency Vulnerability Scanner

Check project dependencies for known CVEs across multiple languages.

```bash
./scripts/audit-deps.sh
./scripts/audit-deps.sh --severity high --fix
```

**Auto-detect:** Node (npm audit), Python (pip-audit), Go (govulncheck), Rust (cargo audit), Ruby (bundle audit).
**Exit:** 0 if no critical/high, 1 if critical, 2 if high.

---

## Usage in Skills

Skills reference these scripts mechanically. Example from `05-security-reviewer/SKILL.md`:

```bash
# Scan for secrets
security-sentinel.sh --text --severity CRITICAL src/

# Audit dependencies
audit-deps.sh --severity high --fix

# Log gate results
verify-gate.sh --gate-name "secret-scan" --command "security-sentinel.sh src/" --log security-gates.tsv
```

---

### 6. `log-learning.sh` — Operational Learning Logger (v1.5.0)

Logs durable project quirks, command fixes, and time-saving insights discovered during skill execution. Learnings compound across sessions.

```bash
./scripts/log-learning.sh --skill bug-hunter --type gotcha \
    --key "jest-cache-stale" \
    --insight "Jest --no-cache fixes 90% of 'test passes locally, fails in CI' issues."

./scripts/log-learning.sh --skill backend-architect --type pattern \
    --key "pg-pool-sizing" \
    --insight "Postgres connection pool = (CPU cores * 2) + spindle count." \
    --confidence 1.0
```

**Learning types:** `operational` (command fixes), `pattern` (reusable patterns), `fix` (solutions to recurring bugs), `gotcha` (library/doc surprises), `config` (project-specific conventions).

**Output:** Appends JSONL to `~/.virtual-company/projects/<project-slug>/learnings.jsonl`. Project slug is auto-detected from git repo or directory name.

**Exit:** 0 on success, 1 on invalid args.

---

### 7. `gen-skills.sh` — Template Pipeline Generator (v1.6.0)

Composes SKILL.md files from `.spec` files + tier-selected resolver components. Edit a resolver to propagate that guardrail to every tier that includes it.

```bash
# Generate a single skill from its .spec file
./scripts/gen-skills.sh --skill skills/02-bug-hunter

# Regenerate all skills (requires .spec files)
./scripts/gen-skills.sh --all

# List tier + template status for all skills
./scripts/gen-skills.sh --list

# Validate all .spec files (sections, tier, {{GUARDRAILS}} marker)
./scripts/gen-skills.sh --validate
```

**Architecture:**
- `skills/_templates/resolvers/*.md` — Reusable guardrail components (13: voice, completion, learning-log, confusion, ask-user-format, context-decay, sub-agent-swarming, edit-integrity, verification-discipline, effort-table, escalation, rollback, secret-scan)
- `skills/XX-skill/SKILL.md.spec` — Per-skill source of truth, ending with a single `{{GUARDRAILS}}` marker
- `skills/XX-skill/SKILL.md` — Generated output (do not hand-edit; re-running `gen-skills.sh` overwrites it)

**Tier composition** — the spec's `preamble-tier` selects which resolvers land in `{{GUARDRAILS}}`:

| Tier | Guardrails injected |
|------|---------------------|
| T1 | voice, completion, learning-log |
| T2 | + confusion, ask-user-format |
| T3 | + context-decay, sub-agent-swarming, edit-integrity, verification-discipline, effort-table |
| T4 | + escalation, rollback, secret-scan |

A resolver is skipped when the skill already covers it in its own words, so hand-written sections are never duplicated.

### 8. `load-learnings.sh` — Session-Start Learning Loader (v1.6.0)

Prints the most recent entries from `~/.virtual-company/projects/<slug>/learnings.jsonl`. Wired into the `SessionStart` hook so learnings logged by `log-learning.sh` actually reach the agent.

```bash
./scripts/load-learnings.sh            # last 5 entries
./scripts/load-learnings.sh --lines 10
```

---

## Script Standards

All scripts follow these conventions:

- `#!/usr/bin/env bash` + `set -euo pipefail`
- `--help` flag with usage info
- Colored output (green PASS, red FAIL, yellow WARNING)
- Executable permissions (`chmod +x`)
- Linux (Debian) compatible — no macOS-specific commands
