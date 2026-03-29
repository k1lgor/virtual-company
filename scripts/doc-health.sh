#!/usr/bin/env bash
# doc-health.sh — Documentation Health Check
# Validate project documentation completeness.
# Usage: doc-health.sh [project root directory]
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Help ---
show_help() {
    cat <<EOF
${BOLD}doc-health.sh${NC} — Documentation Health Check

${BOLD}USAGE:${NC}
    doc-health.sh [project root directory]

${BOLD}ARGUMENTS:${NC}
    project root    Path to project root (default: current directory)

${BOLD}CHECKS (10 max):${NC}
    1. README.md exists and has > 200 words
    2. Has Installation/Setup section
    3. Has Usage/Getting Started section
    4. Has API documentation (docs/api* or swagger/openapi)
    5. No TODO/FIXME/HACK in documentation files
    6. Code examples have language tags
    7. Links to local files are not broken
    8. Has CHANGELOG or CHANGES file
    9. Has LICENSE file
    10. Has CONTRIBUTING guide

${BOLD}EXIT CODES:${NC}
    0 = score >= 7 (PASS)
    1 = score < 7 (FAIL)

${BOLD}EXAMPLE:${NC}
    doc-health.sh
    doc-health.sh ./my-project
EOF
    exit 0
}

# --- Parse args ---
PROJECT_ROOT="${1:-.}"

if [[ "$PROJECT_ROOT" == "--help" || "$PROJECT_ROOT" == "-h" ]]; then
    show_help
fi

if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo -e "${RED}ERROR${NC}: Directory not found: $PROJECT_ROOT" >&2
    exit 2
fi

SCORE=0
MISSING=()

# --- Check 1: README.md with >200 words ---
README_SCORE=0
if [[ -f "$PROJECT_ROOT/README.md" ]]; then
    WORD_COUNT=$(wc -w < "$PROJECT_ROOT/README.md")
    if [[ $WORD_COUNT -gt 200 ]]; then
        SCORE=$((SCORE + 1))
        README_SCORE=1
    fi
fi
if [[ $README_SCORE -eq 0 ]]; then
    MISSING+=("README.md with >200 words (found $WORD_COUNT words)")
fi

# --- Check 2: Installation/Setup section ---
if grep -qiE '(#|##).*(install|setup|getting.started|quick.start)' "$PROJECT_ROOT/README.md" 2>/dev/null; then
    SCORE=$((SCORE + 1))
else
    # Check other common files
    if grep -rqiE '(#|##).*(install|setup)' "$PROJECT_ROOT/docs/" 2>/dev/null || \
       grep -qiE '(#|##).*(install|setup)' "$PROJECT_ROOT/INSTALL*" 2>/dev/null; then
        SCORE=$((SCORE + 1))
    else
        MISSING+=("Installation/Setup section")
    fi
fi

# --- Check 3: Usage/Getting Started section ---
if grep -qiE '(#|##).*(usage|getting.started|quickstart|how.to.use)' "$PROJECT_ROOT/README.md" 2>/dev/null; then
    SCORE=$((SCORE + 1))
else
    if grep -rqiE '(#|##).*(usage|getting.started)' "$PROJECT_ROOT/docs/" 2>/dev/null; then
        SCORE=$((SCORE + 1))
    else
        MISSING+=("Usage/Getting Started section")
    fi
fi

# --- Check 4: API documentation ---
API_FOUND=0
if [[ -d "$PROJECT_ROOT/docs" ]]; then
    if find "$PROJECT_ROOT/docs" -iname "api*" -type f 2>/dev/null | head -1 | grep -q .; then
        API_FOUND=1
    fi
fi
if find "$PROJECT_ROOT" -iname "swagger*" -o -iname "openapi*" 2>/dev/null | head -1 | grep -q .; then
    API_FOUND=1
fi
if [[ $API_FOUND -eq 1 ]]; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("API documentation (docs/api*, swagger, or openapi)")
fi

# --- Check 5: No TODO/FIXME/HACK in docs ---
DOC_FILES=$(find "$PROJECT_ROOT" -maxdepth 2 \( -name "*.md" -o -name "*.rst" -o -name "*.txt" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null || true)
TODO_FOUND=0
if [[ -n "$DOC_FILES" ]]; then
    TODO_MATCH=$(echo "$DOC_FILES" | xargs grep -liE '(TODO|FIXME|HACK)\b' 2>/dev/null || true)
    if [[ -n "$TODO_MATCH" ]]; then
        TODO_FOUND=1
        MISSING+=("Documentation files contain TODO/FIXME/HACK markers")
    fi
fi
if [[ $TODO_FOUND -eq 0 ]]; then
    SCORE=$((SCORE + 1))
fi

# --- Check 6: Code blocks have language tags ---
if [[ -n "$DOC_FILES" ]]; then
    UNTAGGED=$(echo "$DOC_FILES" | xargs grep -cE '^\s*```[[:space:]]*$' 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
    TAGGED=$(echo "$DOC_FILES" | xargs grep -cE '^\s*```[a-zA-Z]' 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
    if [[ $TAGGED -gt 0 && $UNTAGGED -le $TAGGED ]]; then
        SCORE=$((SCORE + 1))
    elif [[ $TAGGED -eq 0 && $UNTAGGED -eq 0 ]]; then
        SCORE=$((SCORE + 1))  # No code blocks at all = fine
    else
        MISSING+=("Code blocks missing language tags ($UNTAGGED untagged vs $TAGGED tagged)")
    fi
else
    SCORE=$((SCORE + 1))
fi

# --- Check 7: Local file links are valid ---
BROKEN_LINKS=0
if [[ -n "$DOC_FILES" ]]; then
    # Extract relative links from markdown: [text](./path) or [text](path)
    LINKS=$(echo "$DOC_FILES" | xargs grep -oE '\[.*\]\([^)]+\)' 2>/dev/null | \
        grep -oE '\(([^)]+)\)' | tr -d '()' | grep -vE '^(https?://|mailto:|#)' | head -20 || true)
    if [[ -n "$LINKS" ]]; then
        while IFS= read -r link; do
            # Resolve relative to project root
            if [[ ! -f "$PROJECT_ROOT/$link" && ! -d "$PROJECT_ROOT/$link" ]]; then
                BROKEN_LINKS=$((BROKEN_LINKS + 1))
            fi
        done <<< "$LINKS"
    fi
fi
if [[ $BROKEN_LINKS -eq 0 ]]; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("$BROKEN_LINKS broken file links in documentation")
fi

# --- Check 8: CHANGELOG/CHANGES ---
if find "$PROJECT_ROOT" -maxdepth 1 -iname "CHANGE*" -o -iname "HISTORY*" 2>/dev/null | head -1 | grep -q .; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("CHANGELOG or CHANGES file")
fi

# --- Check 9: LICENSE ---
if find "$PROJECT_ROOT" -maxdepth 1 -iname "LICENSE*" -o -iname "LICENCE*" -o -iname "COPYING*" 2>/dev/null | head -1 | grep -q .; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("LICENSE file")
fi

# --- Check 10: CONTRIBUTING guide ---
if find "$PROJECT_ROOT" -maxdepth 1 -iname "CONTRIBUTING*" 2>/dev/null | head -1 | grep -q .; then
    SCORE=$((SCORE + 1))
else
    MISSING+=("CONTRIBUTING guide")
fi

# --- Output ---
echo -e "${BOLD}=== Documentation Health Check ===${NC}"
echo -e "Project: ${CYAN}$(cd "$PROJECT_ROOT" && pwd)${NC}"
echo ""

if [[ $SCORE -ge 7 ]]; then
    echo -e "Score: ${GREEN}${SCORE}/10${NC} ${GREEN}PASS${NC}"
else
    echo -e "Score: ${RED}${SCORE}/10${NC} ${RED}FAIL${NC}"
fi

echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Missing items:${NC}"
    for item in "${MISSING[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
    echo ""
fi

# --- Exit code ---
if [[ $SCORE -ge 7 ]]; then
    exit 0
else
    exit 1
fi
