#!/usr/bin/env bash
# coverage-gate.sh — Test Coverage Gate
# Run tests and check coverage meets threshold.
# Usage: coverage-gate.sh [--threshold 80] [--command "npm test -- --coverage"] [--reporter json|text]
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
${BOLD}coverage-gate.sh${NC} — Test Coverage Gate

${BOLD}USAGE:${NC}
    coverage-gate.sh [--threshold 80] [--command "npm test -- --coverage"] [--reporter json|text]

${BOLD}OPTIONS:${NC}
    --threshold N      Minimum coverage percentage (default: 80)
    --command CMD      Custom test command (auto-detected if omitted)
    --reporter TYPE    Output format: json or text (default: text)
    --help, -h         Show this help message

${BOLD}AUTO-DETECTION:${NC}
    package.json       → npm test -- --coverage
    requirements.txt   → pytest --cov
    go.mod             → go test -cover

${BOLD}EXIT CODES:${NC}
    0 = coverage >= threshold (PASS)
    1 = coverage < threshold (FAIL)

${BOLD}EXAMPLE:${NC}
    coverage-gate.sh --threshold 90
    coverage-gate.sh --command "pytest --cov --cov-report=term-missing" --threshold 70
    coverage-gate.sh --reporter json
EOF
    exit 0
}

# --- Defaults ---
THRESHOLD=80
COMMAND=""
REPORTER="text"

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --threshold) THRESHOLD="$2"; shift 2 ;;
        --command) COMMAND="$2"; shift 2 ;;
        --reporter) REPORTER="$2"; shift 2 ;;
        --help|-h) show_help ;;
        -*) echo -e "${RED}Unknown option:${NC} $1" >&2; exit 2 ;;
        *) echo -e "${RED}Unexpected argument:${NC} $1" >&2; exit 2 ;;
    esac
done

# --- Auto-detect project type and command ---
if [[ -z "$COMMAND" ]]; then
    if [[ -f "package.json" ]]; then
        COMMAND="npm test -- --coverage"
    elif [[ -f "requirements.txt" || -f "setup.py" || -f "pyproject.toml" ]]; then
        COMMAND="pytest --cov"
    elif [[ -f "go.mod" ]]; then
        COMMAND="go test -cover"
    else
        echo -e "${RED}ERROR${NC}: Could not auto-detect project type." >&2
        echo "Use --command to specify a test command." >&2
        exit 2
    fi
fi

# --- Run tests ---
echo -e "${BOLD}Coverage Gate${NC}"
echo -e "${BOLD}Threshold:${NC} ${THRESHOLD}%"
echo -e "${BOLD}Command:${NC} $COMMAND"
echo ""

OUTPUT=$(eval "$COMMAND" 2>&1) || true
EXIT_CODE=$?

# --- Parse coverage percentage ---
# Try multiple common formats
ACTUAL=$(echo "$OUTPUT" | grep -oE 'All files[[:space:]]*\|[[:space:]]*[0-9]+\.?[0-9]*' | grep -oE '[0-9]+\.?[0-9]*' | tail -1 || true)

if [[ -z "$ACTUAL" ]]; then
    # Go format: coverage: 85.2% of statements
    ACTUAL=$(echo "$OUTPUT" | grep -oE 'coverage: [0-9]+\.[0-9]+%' | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)
fi

if [[ -z "$ACTUAL" ]]; then
    # pytest-cov format: TOTAL    1234    56    95%
    ACTUAL=$(echo "$OUTPUT" | grep -oE 'TOTAL.*[0-9]+%' | grep -oE '[0-9]+%' | grep -oE '[0-9]+' | head -1 || true)
fi

if [[ -z "$ACTUAL" ]]; then
    # Generic: XX% or XX.X%
    ACTUAL=$(echo "$OUTPUT" | grep -oE '[0-9]+\.?[0-9]*%' | grep -oE '[0-9]+\.?[0-9]*' | tail -1 || true)
fi

if [[ -z "$ACTUAL" ]]; then
    echo -e "${YELLOW}WARNING${NC}: Could not parse coverage percentage from output."
    echo ""
    echo "$OUTPUT" | tail -20
    echo ""
    echo -e "${RED}FAIL${NC}: Could not determine coverage"
    exit 1
fi

# --- Compare against threshold ---
# Use bc for float comparison
PASSED=$(echo "$ACTUAL >= $THRESHOLD" | bc 2>/dev/null || echo "0")

# --- Output ---
if [[ "$REPORTER" == "json" ]]; then
    if [[ "$PASSED" -eq 1 ]]; then
        RESULT="true"
    else
        RESULT="false"
    fi
    printf '{"passed":%s,"actual":%.2f,"threshold":%d,"command":"%s"}\n' \
        "$RESULT" "$ACTUAL" "$THRESHOLD" "$COMMAND"
else
    echo -e "${BOLD}Test Output (last 10 lines):${NC}"
    echo "$OUTPUT" | tail -10
    echo ""
    echo -e "${BOLD}Coverage:${NC} ${ACTUAL}%"
    echo -e "${BOLD}Threshold:${NC} ${THRESHOLD}%"
    echo ""
    if [[ "$PASSED" -eq 1 ]]; then
        echo -e "${GREEN}PASS${NC} — Coverage ${ACTUAL}% meets threshold ${THRESHOLD}%"
    else
        echo -e "${RED}FAIL${NC} — Coverage ${ACTUAL}% below threshold ${THRESHOLD}%"
    fi
fi

# --- Exit code ---
if [[ "$PASSED" -eq 1 ]]; then
    exit 0
else
    exit 1
fi
