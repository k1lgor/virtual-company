#!/usr/bin/env bash
# log-learning.sh — Operational Learning Logger
# Logs durable project quirks, command fixes, and time-saving insights
# discovered during skill execution. Learnings compound across sessions.
# Usage: log-learning.sh --skill <name> --type <type> --key <key> --insight <text> [--confidence <0-1>]
set -euo pipefail

# --- Config ---
VC_DIR="${HOME}/.virtual-company"
LEARNINGS_DIR="${VC_DIR}/projects"
SCRIPT_NAME="$(basename "$0")"

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -eq 0 ]]; then
    cat <<EOF
log-learning.sh — Operational Learning Logger

Logs durable project quirks, command fixes, and time-saving insights
that compound across sessions. Use BEFORE completing a skill if you
discovered something that would save 5+ minutes next time.

USAGE:
    log-learning.sh --skill <name> --type <type> --key <key> \\
                    --insight <text> [--confidence <0-1>]

ARGUMENTS:
    --skill NAME       Skill that discovered the learning (e.g., bug-hunter)
    --type TYPE        Learning category: operational | pattern | fix | gotcha | config
    --key KEY          Short unique key (e.g., "jest-cache-clear", "db-reset-sequence")
    --insight TEXT     What you learned — concrete, actionable, one paragraph
    --confidence 0-1   How sure you are this will save time next time (default: 0.8)

EXAMPLES:
    log-learning.sh --skill bug-hunter --type gotcha \\
        --key "jest-cache-stale" \\
        --insight "Jest --no-cache fixes 90% of 'test passes locally, fails in CI' issues. Always try --no-cache before investigating further."

    log-learning.sh --skill code-polisher --type operational \\
        --key "lint-before-refactor" \\
        --insight "Run 'npm run lint -- --fix' BEFORE refactoring. Diffs are cleaner and tests don't break from unrelated lint changes."

    log-learning.sh --skill backend-architect --type pattern \\
        --key "pg-pool-sizing" \\
        --insight "Postgres connection pool = (CPU cores * 2) + effective_spindle_count. Default 10 is too low for 8-core machines under load." \\
        --confidence 1.0

OUTPUT:
    Logs to ~/.virtual-company/projects/<project-slug>/learnings.jsonl
    Project slug is auto-detected from the current git repo or directory name.
EOF
    exit 0
fi

# --- Parse args ---
SKILL=""
TYPE=""
KEY=""
INSIGHT=""
CONFIDENCE="0.8"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)      SKILL="$2";      shift 2 ;;
        --type)       TYPE="$2";       shift 2 ;;
        --key)        KEY="$2";        shift 2 ;;
        --insight)    INSIGHT="$2";    shift 2 ;;
        --confidence) CONFIDENCE="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# --- Validate ---
if [[ -z "$SKILL" || -z "$TYPE" || -z "$KEY" || -z "$INSIGHT" ]]; then
    echo "ERROR: --skill, --type, --key, and --insight are all required."
    echo "Run '$SCRIPT_NAME --help' for usage."
    exit 1
fi

VALID_TYPES="operational pattern fix gotcha config"
if ! echo "$VALID_TYPES" | grep -qw "$TYPE"; then
    echo "ERROR: --type must be one of: $VALID_TYPES"
    exit 1
fi

if ! [[ "$CONFIDENCE" =~ ^0(\.[0-9]+)?$|^1(\.0)?$ ]]; then
    echo "ERROR: --confidence must be a number between 0 and 1 (e.g., 0.8)"
    exit 1
fi

# --- Detect project slug ---
PROJECT_SLUG=""
if git rev-parse --show-toplevel &>/dev/null; then
    PROJECT_SLUG=$(basename "$(git rev-parse --show-toplevel)")
else
    PROJECT_SLUG=$(basename "$PWD")
fi

# --- Ensure directory exists ---
PROJECT_DIR="${LEARNINGS_DIR}/${PROJECT_SLUG}"
mkdir -p "$PROJECT_DIR"

LEARNINGS_FILE="${PROJECT_DIR}/learnings.jsonl"

# Escape a string for embedding in JSON (fallback path only).
json_escape() {
    printf '%s' "$1" \
        | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r//g' \
        | tr '\n' ' '
}

# --- Build JSON ---
# Every branch must emit exactly ONE line: this file is .jsonl, and the reader
# (SessionStart tail / grep) is line-oriented.
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if command -v jq &>/dev/null; then
    # -c = compact: without it jq pretty-prints and one entry becomes 9 lines.
    JSON=$(jq -c -n \
        --arg skill "$SKILL" \
        --arg type "$TYPE" \
        --arg key "$KEY" \
        --arg insight "$INSIGHT" \
        --arg confidence "$CONFIDENCE" \
        --arg timestamp "$TIMESTAMP" \
        --arg repo "$PROJECT_SLUG" \
        '{skill: $skill, type: $type, key: $key, insight: $insight, confidence: ($confidence | tonumber), timestamp: $timestamp, repo: $repo}')
elif command -v python3 &>/dev/null; then
    JSON=$(VC_SKILL="$SKILL" VC_TYPE="$TYPE" VC_KEY="$KEY" VC_INSIGHT="$INSIGHT" \
        VC_CONF="$CONFIDENCE" VC_TS="$TIMESTAMP" VC_REPO="$PROJECT_SLUG" \
        python3 -c 'import json, os
print(json.dumps({
    "skill": os.environ["VC_SKILL"], "type": os.environ["VC_TYPE"],
    "key": os.environ["VC_KEY"], "insight": os.environ["VC_INSIGHT"],
    "confidence": float(os.environ["VC_CONF"]),
    "timestamp": os.environ["VC_TS"], "repo": os.environ["VC_REPO"],
}, separators=(",", ":")))')
else
    # Fallback: manual JSON with escaping and newlines collapsed.
    JSON="{\"skill\":\"$(json_escape "$SKILL")\",\"type\":\"$(json_escape "$TYPE")\",\"key\":\"$(json_escape "$KEY")\",\"insight\":\"$(json_escape "$INSIGHT")\",\"confidence\":${CONFIDENCE},\"timestamp\":\"${TIMESTAMP}\",\"repo\":\"$(json_escape "$PROJECT_SLUG")\"}"
fi

# --- Write ---
echo "$JSON" >> "$LEARNINGS_FILE"

# --- Feedback ---
COUNT=$(wc -l < "$LEARNINGS_FILE" | tr -d ' ')
echo "📝 Learning logged: ${TYPE}/${KEY}"
echo "   Project: ${PROJECT_SLUG}"
echo "   Total learnings: ${COUNT}"
echo "   File: ${LEARNINGS_FILE}"

# --- Load tip ---
if [[ "$COUNT" -eq 1 ]]; then
    echo ""
    echo "💡 Tip: Add to CLAUDE.md or skill preamble to load learnings at session start:"
    echo "   if [ -f ~/.virtual-company/projects/\$(basename \$(git rev-parse --show-toplevel 2>/dev/null || echo \$PWD))/learnings.jsonl ]; then"
    echo "     echo '--- Recent Project Learnings ---'"
    echo "     tail -5 ~/.virtual-company/projects/\$(basename \$(git rev-parse --show-toplevel 2>/dev/null || echo \$PWD))/learnings.jsonl"
    echo "     echo '---'"
    echo "   fi"
fi
