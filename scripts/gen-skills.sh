#!/usr/bin/env bash
# gen-skills.sh — Skill Template Generator (v1.6.0)
# Composes a SKILL.md from a per-skill spec plus reusable resolver components.
#
# Usage:
#   gen-skills.sh --skill <skill-dir>     # Generate single skill
#   gen-skills.sh --all                   # Regenerate ALL skills
#   gen-skills.sh --list                  # List all skills with their tiers
#   gen-skills.sh --validate              # Check specs and placeholder hygiene
#
# Architecture:
#   skills/_templates/resolvers/*.md      ← Reusable guardrail components
#   skills/XX-skill/SKILL.md.spec         ← Per-skill source of truth
#   skills/XX-skill/SKILL.md              ← Generated output (overwritten)
#
# The spec is the single source of truth. The `preamble-tier` field in its
# frontmatter decides WHICH guardrails are injected via {{GUARDRAILS}}:
#
#   T1  voice, completion, learning-log
#   T2  T1 + confusion, ask-user-format
#   T3  T2 + context-decay, sub-agent-swarming, edit-integrity,
#            verification-discipline, effort-table
#   T4  T3 + escalation, rollback, secret-scan
#
# A guardrail is skipped when the skill already covers it in its own words
# (e.g. a skill with a hand-written "Edit Integrity" section does not get the
# generic one injected twice).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="${PROJECT_DIR}/skills/_templates"
RESOLVERS_DIR="${TEMPLATES_DIR}/resolvers"

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -eq 0 ]]; then
    cat <<EOF
gen-skills.sh — Skill Template Generator (v1.6.0)

Composes SKILL.md files from per-skill .spec files + tier-selected resolvers.
Edit a resolver to propagate that guardrail to every tier that includes it.

USAGE:
    gen-skills.sh --skill <skill-dir>     Generate a single skill
    gen-skills.sh --all                   Regenerate all skills
    gen-skills.sh --list                  Show tier + template status per skill
    gen-skills.sh --validate              Check specs and placeholder hygiene

TIER COMPOSITION (from the spec's preamble-tier):
    T1  voice, completion, learning-log
    T2  + confusion, ask-user-format
    T3  + context-decay, sub-agent-swarming, edit-integrity,
        verification-discipline, effort-table
    T4  + escalation, rollback, secret-scan

ARCHITECTURE:
    skills/_templates/resolvers/          Reusable guardrail components
    skills/XX-skill/SKILL.md.spec         Per-skill source of truth
    skills/XX-skill/SKILL.md              Generated output (do not edit)

EXAMPLE:
    gen-skills.sh --skill skills/02-bug-hunter
    gen-skills.sh --all
EOF
    exit 0
fi

# --- Tier → guardrail composition (single source of truth) ---
guardrails_for_tier() {
    case "${1:-2}" in
        1) echo "voice completion learning-log" ;;
        2) echo "voice completion learning-log confusion ask-user-format" ;;
        3) echo "voice completion learning-log confusion ask-user-format context-decay sub-agent-swarming edit-integrity verification-discipline effort-table" ;;
        4) echo "voice completion learning-log confusion ask-user-format context-decay sub-agent-swarming edit-integrity verification-discipline effort-table escalation rollback secret-scan" ;;
        *) echo "voice completion learning-log confusion ask-user-format" ;;
    esac
}

# --- Marker used to detect that a skill already covers a guardrail ---
resolver_marker() {
    case "$1" in
        voice)                   echo "Voice Directive" ;;
        completion)              echo "Completion Status Protocol" ;;
        confusion)               echo "Confusion Protocol" ;;
        ask-user-format)         echo "AskUserQuestion" ;;
        effort-table)            echo "Effort Compression" ;;
        learning-log)            echo "Operational Self-Improvement" ;;
        context-decay)           echo "Context Decay" ;;
        sub-agent-swarming)      echo "Sub-Agent Swarm" ;;
        edit-integrity)          echo "Edit Integrity" ;;
        verification-discipline) echo "Verification Discipline" ;;
        escalation)              echo "Escalation" ;;
        rollback)                echo "Rollback" ;;
        secret-scan)             echo "Secret Scan" ;;
        *)                       echo "" ;;
    esac
}

TIER="2"
SPEC=""
SKILL_TOOLS=""
SEEN=""

emit_resolver() {
    local name="$1"
    local marker file
    marker=$(resolver_marker "$name")
    file="${RESOLVERS_DIR}/${name}.md"

    if [[ ! -f "$file" ]]; then
        echo "  ⚠️  missing resolver ${name}.md" >&2
        return 0
    fi

    # A guardrail that names a specific tool is noise on a skill that cannot use
    # that tool — e.g. telling an advisory, read-only skill to "re-read before
    # every edit" when it was never granted Edit.
    if [[ "$name" == "edit-integrity" && "$SKILL_TOOLS" != *"Edit"* ]]; then
        return 0
    fi

    # Already covered by the skill's own prose — do not duplicate.
    if [[ -n "$marker" && "$SPEC" == *"$marker"* ]]; then
        return 0
    fi

    # Already emitted in this pass.
    if [[ " $SEEN " == *" $name "* ]]; then
        return 0
    fi
    SEEN="${SEEN} ${name}"

    cat "$file"
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

    SPEC=$(cat "$spec_file")
    TIER=$(printf '%s' "$SPEC" | sed -n 's/^preamble-tier:[[:space:]]*\([0-9]\).*/\1/p' | head -1)
    [[ -z "$TIER" ]] && TIER="2"
    # Granted tools drive capability-aware guardrail composition.
    SKILL_TOOLS=$(printf '%s' "$SPEC" | sed -n 's/^allowed-tools:[[:space:]]*\(.*\)/\1/p' | head -1)
    SEEN=""

    echo "  📝 ${skill_name} (T${TIER})..."

    local tmp_output="${output_file}.tmp"
    {
        while IFS= read -r line || [[ -n "$line" ]]; do
            case "$line" in
                "{{GUARDRAILS}}")
                    for r in $(guardrails_for_tier "$TIER"); do
                        emit_resolver "$r"
                    done
                    ;;
                "{{VOICE}}")            emit_resolver voice ;;
                "{{COMPLETION}}")       emit_resolver completion ;;
                "{{CONFUSION}}")        emit_resolver confusion ;;
                "{{ASK_USER_FORMAT}}")  emit_resolver ask-user-format ;;
                "{{EFFORT_TABLE}}")     emit_resolver effort-table ;;
                "{{LEARNING_LOG}}")     emit_resolver learning-log ;;
                *)                      printf '%s\n' "$line" ;;
            esac
        done < "$spec_file"
    } > "$tmp_output"

    mv "$tmp_output" "$output_file"

    local line_count
    line_count=$(wc -l < "$output_file" | tr -d ' ')
    echo "     ✅ generated (${line_count} lines)"
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
    printf "%-32s %-6s %-8s %-6s\n" "Skill" "Tier" "Has .spec" "Lines"
    printf "%-32s %-6s %-8s %-6s\n" "-----" "----" "---------" "-----"

    for skill_dir in "${PROJECT_DIR}/skills"/*/; do
        local name
        name=$(basename "$skill_dir")
        [[ "$name" == "_templates" ]] && continue

        local tier="?"
        local has_spec="❌"
        local lines=0
        if [[ -f "${skill_dir}/SKILL.md.spec" ]]; then
            has_spec="✅"
            tier=$(grep -m1 -o 'preamble-tier:[[:space:]]*[0-9]' "${skill_dir}/SKILL.md.spec" | grep -o '[0-9]' || echo "?")
        fi
        if [[ -f "${skill_dir}/SKILL.md" ]]; then
            lines=$(wc -l < "${skill_dir}/SKILL.md" | tr -d ' ')
        fi

        printf "%-32s %-6s %-8s %-6s\n" "$name" "T${tier}" "$has_spec" "$lines"
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

        grep -q "Iron Law" "$spec_file" || issues+=("missing Iron Law")
        grep -q "HARD-GATE" "$spec_file" || issues+=("missing HARD-GATE")
        grep -q "Failure Modes" "$spec_file" || issues+=("missing Failure Modes")
        grep -q "Red Flags" "$spec_file" || issues+=("missing Red Flags")
        grep -q "Verification" "$spec_file" || issues+=("missing Verification")
        grep -q "Decision Tree" "$spec_file" || issues+=("missing Decision Tree")
        grep -q "Collaborative Links" "$spec_file" || issues+=("missing Collaborative Links")

        local tier
        tier=$(sed -n 's/^preamble-tier:[[:space:]]*\([0-9]\).*/\1/p' "$spec_file" | head -1)
        if [[ -z "$tier" ]]; then
            issues+=("missing preamble-tier")
        elif [[ ! "$tier" =~ ^[1-4]$ ]]; then
            issues+=("invalid preamble-tier: ${tier}")
        fi

        if ! grep -q "{{GUARDRAILS}}" "$spec_file"; then
            issues+=("missing {{GUARDRAILS}} marker")
        fi

        # Stale single-resolver placeholders left over from the pre-1.6 layout.
        if grep -qE '\{\{(VOICE|COMPLETION|CONFUSION|ASK_USER_FORMAT|EFFORT_TABLE|LEARNING_LOG)\}\}' "$spec_file"; then
            issues+=("legacy placeholder present — replace with {{GUARDRAILS}}")
        fi

        if [[ ${#issues[@]} -eq 0 ]]; then
            echo "  ✅ T${tier} ${name}"
            valid=$((valid + 1))
        else
            echo "  ❌ ${name}: ${issues[*]}"
            invalid=$((invalid + 1))
        fi
    done

    echo ""
    echo "Valid: ${valid} | Invalid: ${invalid}"
    [[ $invalid -eq 0 ]]
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
