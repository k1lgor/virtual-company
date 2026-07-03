#!/usr/bin/env bash
# gen-skills.sh — Skill Template Generator
# Composes a SKILL.md from a .tmpl file + resolver components.
# This is the template pipeline inspired by gstack v1.58 architecture.
#
# Usage:
#   gen-skills.sh --skill <skill-dir>     # Generate single skill
#   gen-skills.sh --all                   # Regenerate ALL skills
#   gen-skills.sh --list                  # List all skills with their templates
#
# Architecture:
#   skills/_templates/SKILL.md.tmpl       ← Master template ({{PLACEHOLDERS}})
#   skills/_templates/resolvers/*.md      ← Reusable section components
#   skills/XX-skill/SKILL.md.spec         ← Per-skill spec (YAML frontmatter + custom content)
#   skills/XX-skill/SKILL.md              ← Generated output
#
# Generated SKILL.md files are safe to edit directly, but re-running
# gen-skills.sh overwrites them. For persistent changes, edit the .spec
# or resolver files instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="${PROJECT_DIR}/skills/_templates"
RESOLVERS_DIR="${TEMPLATES_DIR}/resolvers"
MASTER_TMPL="${TEMPLATES_DIR}/SKILL.md.tmpl"

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -eq 0 ]]; then
    cat <<EOF
gen-skills.sh — Skill Template Generator (v1.5.0)

Composes SKILL.md files from .tmpl templates + resolver components.
Edit resolver files to propagate changes to ALL skills, or edit
per-skill .spec files for skill-specific content.

USAGE:
    gen-skills.sh --skill <skill-dir>     Generate a single skill
    gen-skills.sh --all                   Regenerate all 27 skills
    gen-skills.sh --list                  Show template status for all skills
    gen-skills.sh --validate              Check all .spec files for completeness

ARCHITECTURE:
    skills/_templates/SKILL.md.tmpl       Master template with {{PLACEHOLDERS}}
    skills/_templates/resolvers/          Reusable section components:
        voice.md          — Voice Directive (writing style + banned words)
        completion.md     — Completion Status Protocol (DONE/BLOCKED/...)
        confusion.md      — Confusion Protocol (STOP-and-ask guardrail)
        ask-user-format.md — AskUserQuestion Decision Brief format
        effort-table.md   — AI Effort Compression Reference
        learning-log.md   — Operational Self-Improvement (learning log)
    skills/XX-skill/SKILL.md.spec         Per-skill specification
    skills/XX-skill/SKILL.md              Generated output (overwritten by gen-skills.sh)

EXAMPLE:
    # Generate a single skill
    gen-skills.sh --skill skills/02-bug-hunter

    # Regenerate all skills after editing a resolver
    gen-skills.sh --all

    # See which skills have .spec files
    gen-skills.sh --list
EOF
    exit 0
fi

# --- Resolve a placeholder ---
resolve() {
    local placeholder="$1"
    case "$placeholder" in
        "{{VOICE}}")
            cat "${RESOLVERS_DIR}/voice.md" 2>/dev/null || true
            ;;
        "{{COMPLETION}}")
            cat "${RESOLVERS_DIR}/completion.md" 2>/dev/null || true
            ;;
        "{{CONFUSION}}")
            cat "${RESOLVERS_DIR}/confusion.md" 2>/dev/null || true
            ;;
        "{{ASK_USER_FORMAT}}")
            cat "${RESOLVERS_DIR}/ask-user-format.md" 2>/dev/null || true
            ;;
        "{{EFFORT_TABLE}}")
            cat "${RESOLVERS_DIR}/effort-table.md" 2>/dev/null || true
            ;;
        "{{LEARNING_LOG}}")
            cat "${RESOLVERS_DIR}/learning-log.md" 2>/dev/null || true
            ;;
        *)
            # Unknown placeholder — leave as-is
            echo "$placeholder"
            ;;
    esac
}

# --- Generate a single skill from its .spec file ---
generate_skill() {
    local skill_dir="$1"
    local skill_name
    skill_name=$(basename "$skill_dir")
    local spec_file="${skill_dir}/SKILL.md.spec"
    local output_file="${skill_dir}/SKILL.md"

    if [[ ! -f "$spec_file" ]]; then
        echo "  ⚠️  No SKILL.md.spec found for ${skill_name} — skipping (no template source)"
        return 1
    fi

    echo "  📝 Generating ${skill_name}/SKILL.md from .spec..."

    local tmp_output="${output_file}.tmp"

    # Copy spec to working file
    cp "$spec_file" "$tmp_output"

    # Substitute each known placeholder with its resolver content.
    # Uses a temp file approach: read line by line, when we hit a
    # placeholder line (e.g. {{VOICE}}), inject the resolver file.
    {
        while IFS= read -r line || [[ -n "$line" ]]; do
            case "$line" in
                "{{VOICE}}")
                    if [[ -f "${RESOLVERS_DIR}/voice.md" ]]; then
                        cat "${RESOLVERS_DIR}/voice.md"
                    fi
                    ;;
                "{{COMPLETION}}")
                    if [[ -f "${RESOLVERS_DIR}/completion.md" ]]; then
                        cat "${RESOLVERS_DIR}/completion.md"
                    fi
                    ;;
                "{{CONFUSION}}")
                    if [[ -f "${RESOLVERS_DIR}/confusion.md" ]]; then
                        cat "${RESOLVERS_DIR}/confusion.md"
                    fi
                    ;;
                "{{ASK_USER_FORMAT}}")
                    if [[ -f "${RESOLVERS_DIR}/ask-user-format.md" ]]; then
                        cat "${RESOLVERS_DIR}/ask-user-format.md"
                    fi
                    ;;
                "{{EFFORT_TABLE}}")
                    if [[ -f "${RESOLVERS_DIR}/effort-table.md" ]]; then
                        cat "${RESOLVERS_DIR}/effort-table.md"
                    fi
                    ;;
                "{{LEARNING_LOG}}")
                    if [[ -f "${RESOLVERS_DIR}/learning-log.md" ]]; then
                        cat "${RESOLVERS_DIR}/learning-log.md"
                    fi
                    ;;
                *)
                    echo "$line"
                    ;;
            esac
        done < "$spec_file"
    } > "$tmp_output"

    mv "$tmp_output" "$output_file"

    local line_count
    line_count=$(wc -l < "$output_file" | tr -d ' ')
    echo "  ✅ ${skill_name}/SKILL.md generated (${line_count} lines)"
}

# --- Generate all skills ---
generate_all() {
    local generated=0
    local skipped=0

    echo "=== Skill Template Generator ==="
    echo ""

    for skill_dir in "${PROJECT_DIR}/skills"/*/; do
        local name
        name=$(basename "$skill_dir")
        # Skip _templates directory
        [[ "$name" == "_templates" ]] && continue

        if generate_skill "$skill_dir"; then
            generated=$((generated + 1))
        else
            skipped=$((skipped + 1))
        fi
    done

    echo ""
    echo "=== Summary ==="
    echo "Generated: ${generated} | Skipped (no .spec): ${skipped}"
}

# --- List all skills ---
list_skills() {
    echo "=== Skill Template Status ==="
    printf "%-40s %-8s %-6s\n" "Skill" "Has .spec" "Lines"
    printf "%-40s %-8s %-6s\n" "-----" "--------" "-----"

    for skill_dir in "${PROJECT_DIR}/skills"/*/; do
        local name
        name=$(basename "$skill_dir")
        [[ "$name" == "_templates" ]] && continue

        local has_spec="❌"
        local lines=0
        if [[ -f "${skill_dir}/SKILL.md.spec" ]]; then
            has_spec="✅"
        fi
        if [[ -f "${skill_dir}/SKILL.md" ]]; then
            lines=$(wc -l < "${skill_dir}/SKILL.md" | tr -d ' ')
        fi

        printf "%-40s %-8s %-6s\n" "$name" "$has_spec" "$lines"
    done
}

# --- Validate all .spec files ---
validate_specs() {
    echo "=== Validating .spec files ==="
    local valid=0
    local invalid=0

    for spec_file in "${PROJECT_DIR}/skills"/*/SKILL.md.spec; do
        local name
        name=$(basename "$(dirname "$spec_file")")
        [[ "$name" == "_templates" ]] && continue

        local issues=()

        # Check for required sections
        grep -q "Iron Law" "$spec_file" || issues+=("missing Iron Law")
        grep -q "HARD-GATE" "$spec_file" || issues+=("missing HARD-GATE")
        grep -q "Failure Modes" "$spec_file" || issues+=("missing Failure Modes")
        grep -q "Red Flags" "$spec_file" || issues+=("missing Red Flags")
        grep -q "Verification" "$spec_file" || issues+=("missing Verification")
        grep -q "Decision Tree" "$spec_file" || issues+=("missing Decision Tree")
        grep -q "Collaborative Links" "$spec_file" || issues+=("missing Collaborative Links")
        grep -q "preamble-tier" "$spec_file" || issues+=("missing preamble-tier")

        if [[ ${#issues[@]} -eq 0 ]]; then
            echo "  ✅ ${name}"
            valid=$((valid + 1))
        else
            echo "  ❌ ${name}: ${issues[*]}"
            invalid=$((invalid + 1))
        fi
    done

    echo ""
    echo "Valid: ${valid} | Invalid: ${invalid}"
}

# --- Main ---
case "${1:-}" in
    --skill)
        if [[ -z "${2:-}" ]]; then
            echo "ERROR: --skill requires a skill directory path"
            exit 1
        fi
        generate_skill "$2"
        ;;
    --all)
        generate_all
        ;;
    --list)
        list_skills
        ;;
    --validate)
        validate_specs
        ;;
    *)
        echo "ERROR: Unknown option: $1"
        echo "Run '$0 --help' for usage."
        exit 1
        ;;
esac
