#!/usr/bin/env bash
# validate-skill.sh — Skill Quality Validator
# Checks if a SKILL.md has all required sections and returns a quality score.
# Usage: validate-skill.sh <SKILL.md path>
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Help ---
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
${BOLD}validate-skill.sh${NC} — Skill Quality Validator

${BOLD}USAGE:${NC}
    validate-skill.sh <SKILL.md path>

${BOLD}DESCRIPTION:${NC}
    Validates a SKILL.md file for completeness and quality.
    Checks for required sections, placeholders, examples, and code blocks.

${BOLD}REQUIRED SECTIONS:${NC}
    1. Iron Law / iron-law
    2. HARD-GATE (literal tag)
    3. Failure Modes / failure-modes
    4. Red Flags / Anti-Pattern
    5. Verification / verification-checklist
    6. Decision Tree / mermaid / flowchart
    7. Collaborative Links / collaborative-links

${BOLD}SCORING (10 max):${NC}
    - 1 point per required section (7 max)
    - 1 point for no placeholders (TODO, TBD, FIXME, etc.)
    - 1 point for examples section
    - 1 point for concrete code blocks

${BOLD}EXIT CODES:${NC}
    0 = score >= 9 (PASS)
    1 = score < 9 (FAIL)

${BOLD}EXAMPLE:${NC}
    validate-skill.sh ./skills/02-bug-hunter/SKILL.md
EOF
    exit 0
fi

# --- Input validation ---
if [[ $# -lt 1 ]]; then
    echo -e "${RED}ERROR${NC}: Missing required argument: SKILL.md path" >&2
    echo "Run with --help for usage info." >&2
    exit 2
fi

SKILL_FILE="$1"

if [[ ! -f "$SKILL_FILE" ]]; then
    echo -e "${RED}ERROR${NC}: File not found: $SKILL_FILE" >&2
    exit 2
fi

SCORE=0
MAX_SCORE=10
MISSING=()

# --- Section checks (7 points) ---
# Each check: case-insensitive grep for the pattern
check_section() {
    local name="$1"
    shift
    local found=0
    for pattern in "$@"; do
        if grep -qi "$pattern" "$SKILL_FILE" 2>/dev/null; then
            found=1
            break
        fi
    done
    if [[ $found -eq 1 ]]; then
        SCORE=$((SCORE + 1))
    else
        MISSING+=("$name")
    fi
}

check_section "Iron Law"         "iron law" "iron-law" "iron_law"
check_section "HARD-GATE"        "HARD-GATE" "HARD.GATE"
check_section "Failure Modes"    "failure modes" "failure-modes" "failure_modes"
check_section "Red Flags"        "red flags" "red-flags" "red_flags" "anti-pattern" "anti pattern"
check_section "Verification"     "verification" "verification-checklist" "verification_checklist"
check_section "Decision Tree"    "decision tree" "mermaid" "flowchart" "decision-tree"
check_section "Collaborative Links" "collaborative links" "collaborative-links" "collaborative_links"

# --- Placeholder check (1 point) ---
PLACEHOLDER_FOUND=0
PLACEHOLDER_PATTERN="TODO\|TBD\|FIXME\|implement later\|add appropriate"
PLACEHOLDER_LINES=$(grep -in "$PLACEHOLDER_PATTERN" "$SKILL_FILE" 2>/dev/null | head -5 || true)
if [[ -n "$PLACEHOLDER_LINES" ]]; then
    PLACEHOLDER_FOUND=1
else
    SCORE=$((SCORE + 1))
fi

# --- Examples section check (1 point) ---
if grep -qi "example\|examples" "$SKILL_FILE" 2>/dev/null; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("Examples section")
fi

# --- Code blocks check (1 point) ---
# Look for fenced code blocks with language tags
CODE_BLOCK_COUNT=$(grep -c '^\s*```[a-zA-Z]' "$SKILL_FILE" 2>/dev/null || echo 0)
if [[ "$CODE_BLOCK_COUNT" -ge 1 ]]; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("Concrete code blocks (fenced with language tags)")
fi

# --- Output ---
echo -e "${BOLD}=== Skill Quality Validator ===${NC}"
echo -e "File: ${CYAN}$SKILL_FILE${NC}"
echo ""

if [[ $SCORE -ge 9 ]]; then
    echo -e "Score: ${GREEN}${SCORE}/${MAX_SCORE}${NC} ${GREEN}PASS${NC}"
else
    echo -e "Score: ${RED}${SCORE}/${MAX_SCORE}${NC} ${RED}FAIL${NC}"
fi

echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Missing sections:${NC}"
    for item in "${MISSING[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
    echo ""
fi

if [[ $PLACEHOLDER_FOUND -eq 1 ]]; then
    echo -e "${YELLOW}Placeholders found:${NC}"
    echo "$PLACEHOLDER_LINES" | while IFS= read -r line; do
        echo -e "  ${YELLOW}⚠${NC}  $line"
    done
    echo ""
fi

# --- Exit code ---
if [[ $SCORE -ge 9 ]]; then
    exit 0
else
    exit 1
fi
