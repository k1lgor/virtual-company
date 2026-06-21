# Changelog

All notable changes to the Virtual Company plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] — 2026-06-21

### Added

- Examples section added to `19-observability-specialist` SKILL.md (structured logging, Prometheus/Grafana, OpenTelemetry tracing, alert rules)

### Fixed

- Stale references to deleted scripts (`doc-health.sh`, `tsv-log.sh`, `dockerfile-lint.sh`) in README.md, commands/skills.md, and skills/01-doc-writer/SKILL.md
- PostToolUse lint hook now gracefully skips when no linter is configured (instead of erroring)

### Changed

- Agent frontmatter: `qa-engineer` added missing `disallowedTools` (Edit, Bash), fixed `maxTurns` spacing
- Agent frontmatter: `tech-lead` fixed `maxTurns` spacing
- `docs/` directory now tracked in git (was gitignored); `.pantheon/` added to `.gitignore`

## [1.4.0] — 2026-04-30

### Added

- `performance-profiler` added to Domain Expert Registry in Infrastructure category (was missing from CLAUDE.md, README, and commands/skills.md — table listed 26 but 27 skills exist)
- Examples section added to `00-tech-lead` SKILL.md (now 10/10 validation score)
- `docs/plans/` directory created (referenced throughout documentation and agents but didn't exist)

### Fixed

- Agent naming consistency: README used `reviewer` instead of `code-reviewer`, and `security` instead of `security-reviewer` — now matches actual agent files and CLAUDE.md
- PreToolUse security hook in `hooks/hooks.json` was non-functional (grepped `/dev/stdin` which never received content) — replaced with working `prompt`-type warning
- `skill-generator` was listed in two categories (Orchestration and Meta) in `commands/skills.md` — removed duplicate Meta category

### Removed

- `.agent/` directory with 59 legacy/non-advertised skills and placeholder hooks (already gitignored, now fully purged from disk)
- `tsv-log.sh` — autoresearch-specific logger, not core to virtual-company
- `dockerfile-lint.sh` — Docker-only tool, not general-purpose
- `doc-health.sh` — generic documentation checker, not central to multi-agent orchestration

### Changed

- Verification scripts reduced from 8 to 5 (kept: validate-skill, security-sentinel, verify-gate, coverage-gate, audit-deps)
- Plugin description updated to reflect 5 verification scripts
- README project structure diagram now shows all actual directories (`commands/`, `scripts/`, `.claude-plugin/`)

## [1.3.1] — 2026-04-01

### Fixed

- Fixed hooks.json schema to use `PostToolUse` correctly with required hooks arrays
- Fixed README install instructions — clarified GitHub shorthand usage vs plugin name
- Fixed plugin.json repository field from object to string format

### Changed

- Updated initialization message to v1.3.1
- Lint command changed to `bun run lint`

## [1.3.0] — 2026-03-31

### Added

- Mechanical overrides and agent directives for operational rules (Step 0 rule, phased execution, senior dev override, forced verification, sub-agent swarming, context decay awareness, file read budget, tool result blindness, edit integrity, no semantic search)
- Hard gates for: task completion, pre-commit, refactors, and file edits
- Hard gate enforcement section in CLAUDE.md

### Changed

- Refactored all 27 skills with standardized mechanical directives and operational guidance
- Decision trees, failure modes, and red flags sections standardized across skills

## [1.2.0] — 2026-03-31

### Added

- Token and cost awareness sections across skill documentation
- Concrete examples for cost-aware patterns

### Changed

- Version bumped to 1.2.0

## [1.1.0] — 2026-03-22

### Added

- Native plugin architecture (`plugin.json`, `marketplace.json`)
- Automated lifecycle hooks (`hooks.json`)
- 8 verification scripts (validate-skill, security-sentinel, verify-gate, tsv-log, coverage-gate, dockerfile-lint, audit-deps, doc-health)

### Changed

- Upgraded from standalone skills to full Claude Code plugin format
- Skills moved to `./skills/` directory with numbered prefixes
- Agents moved to `./agents/` directory

## [1.0.0] — 2026-02-04

### Added

- Initial release
- 27 domain expert skills with Hard Gates, Iron Laws, Decision Trees, Failure Modes
- 6 strategic role agents (planner, architect, tech-lead, code-reviewer, security-reviewer, qa-engineer)
- Skills command (`/virtual-company:skills`) for listing and filtering experts
- CLAUDE.md with orchestration flow, decision trees, and failure modes
- MIT License

[1.4.1]: https://github.com/k1lgor/virtual-company/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/k1lgor/virtual-company/compare/v1.3.1...v1.4.0
[1.3.1]: https://github.com/k1lgor/virtual-company/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/k1lgor/virtual-company/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/k1lgor/virtual-company/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/k1lgor/virtual-company/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/k1lgor/virtual-company/releases/tag/v1.0.0
