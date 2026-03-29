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

Scans files for leaked secrets and credentials across 13+ patterns.

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

### 4. `tsv-log.sh` — Autoresearch TSV Logger

Log iteration results for autoresearch tracking with automatic delta calculation.

```bash
./scripts/tsv-log.sh --iteration 3 --skill "bug-hunter" --metric 8.5 --status keep --description "Found critical bug"
./scripts/tsv-log.sh --summary
```

**Log format:** `iteration | timestamp | skill | metric | delta | status | description`
**Summary:** Total iterations, keep rate, best metric per skill.
**Status:** `keep`, `discard`, or `fix`.

---

### 5. `coverage-gate.sh` — Test Coverage Gate

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

### 6. `dockerfile-lint.sh` — Dockerfile Best Practices Checker

Validate Dockerfiles against 10 security and best practice rules.

```bash
./scripts/dockerfile-lint.sh ./Dockerfile
./scripts/dockerfile-lint.sh ./deploy/Dockerfile.prod
```

**Rules:** USER instruction, HEALTHCHECK, multi-stage build, no broad COPY/ADD, no privileged ports, specific image tags, no apt-get upgrade, LABEL metadata, no secrets in ENV/ARG, .dockerignore.
**Exit:** 0 if score ≥ 8/10, 1 otherwise.

---

### 7. `audit-deps.sh` — Dependency Vulnerability Scanner

Check project dependencies for known CVEs.

```bash
./scripts/audit-deps.sh
./scripts/audit-deps.sh --severity high --fix
```

**Auto-detect:** Node (npm audit), Python (pip-audit), Go (govulncheck), Rust (cargo audit), Ruby (bundle audit).
**Exit:** 0 if no critical/high, 1 if critical, 2 if high.

---

### 8. `doc-health.sh` — Documentation Health Check

Validate project documentation completeness (10 checks).

```bash
./scripts/doc-health.sh ./
```

**Checks:** README (>200 words), Installation section, Usage section, API docs, no TODO/FIXME, tagged code blocks, valid links, CHANGELOG, LICENSE, CONTRIBUTING.
**Exit:** 0 if score ≥ 7/10, 1 otherwise.

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

## Script Standards

All scripts follow these conventions:

- `#!/usr/bin/env bash` + `set -euo pipefail`
- `--help` flag with usage info
- Colored output (green PASS, red FAIL, yellow WARNING)
- Executable permissions (`chmod +x`)
- Comments explaining each section
- Linux (Debian) compatible — no macOS-specific commands
