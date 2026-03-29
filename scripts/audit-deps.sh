#!/usr/bin/env bash
# audit-deps.sh — Dependency Vulnerability Scanner
# Check project dependencies for known CVEs.
# Usage: audit-deps.sh [--severity LEVEL] [--fix]
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
${BOLD}audit-deps.sh${NC} — Dependency Vulnerability Scanner

${BOLD}USAGE:${NC}
    audit-deps.sh [--severity LEVEL] [--fix]

${BOLD}OPTIONS:${NC}
    --severity LEVEL   Only show vulnerabilities >= level (critical, high, medium, low)
    --fix              Suggest fix commands
    --help, -h         Show this help message

${BOLD}AUTO-DETECTION:${NC}
    package.json       → npm audit --json
    requirements.txt   → pip-audit (fallback: safety check)
    go.mod             → govulncheck ./...
    Cargo.toml         → cargo audit --json
    Gemfile            → bundle audit check --json

${BOLD}EXIT CODES:${NC}
    0 = no critical/high vulnerabilities
    1 = critical vulnerabilities found
    2 = high vulnerabilities found (no critical)

${BOLD}EXAMPLE:${NC}
    audit-deps.sh
    audit-deps.sh --severity high --fix
EOF
    exit 0
}

# --- Defaults ---
SEVERITY_FILTER=""
SHOW_FIX=0

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --severity) SEVERITY_FILTER="$2"; shift 2 ;;
        --fix) SHOW_FIX=1; shift ;;
        --help|-h) show_help ;;
        -*) echo -e "${RED}Unknown option:${NC} $1" >&2; exit 2 ;;
        *) echo -e "${RED}Unexpected argument:${NC} $1" >&2; exit 2 ;;
    esac
done

# --- Severity rank helper ---
severity_rank() {
    case "$1" in
        critical) echo 4 ;;
        high) echo 3 ;;
        moderate|medium) echo 2 ;;
        low) echo 1 ;;
        *) echo 0 ;;
    esac
}

should_show() {
    local sev="$1"
    if [[ -z "$SEVERITY_FILTER" ]]; then
        return 0
    fi
    local filter_rank=$(severity_rank "$SEVERITY_FILTER")
    local sev_rank=$(severity_rank "$sev")
    [[ $sev_rank -ge $filter_rank ]]
}

# --- Auto-detect project type ---
PROJECT_TYPE=""
AUDIT_CMD=""

if [[ -f "package.json" ]]; then
    PROJECT_TYPE="node"
    AUDIT_CMD="npm audit --json 2>/dev/null"
elif [[ -f "requirements.txt" || -f "setup.py" || -f "pyproject.toml" ]]; then
    PROJECT_TYPE="python"
    if command -v pip-audit &>/dev/null; then
        AUDIT_CMD="pip-audit --format json 2>/dev/null"
    elif command -v safety &>/dev/null; then
        AUDIT_CMD="safety check --json 2>/dev/null"
    else
        AUDIT_CMD="pip-audit --format json 2>/dev/null"
    fi
elif [[ -f "go.mod" ]]; then
    PROJECT_TYPE="go"
    AUDIT_CMD="govulncheck ./... 2>/dev/null"
elif [[ -f "Cargo.toml" ]]; then
    PROJECT_TYPE="rust"
    AUDIT_CMD="cargo audit --json 2>/dev/null"
elif [[ -f "Gemfile" ]]; then
    PROJECT_TYPE="ruby"
    AUDIT_CMD="bundle audit check --json 2>/dev/null"
else
    echo -e "${RED}ERROR${NC}: Could not detect project type." >&2
    echo "Supported: Node (package.json), Python (requirements.txt), Go (go.mod), Rust (Cargo.toml), Ruby (Gemfile)" >&2
    exit 2
fi

echo -e "${BOLD}=== Dependency Audit ===${NC}"
echo -e "Project: ${CYAN}$PROJECT_TYPE${NC}"
echo ""

# --- Run audit ---
OUTPUT=$(eval "$AUDIT_CMD" 2>&1) || true

# --- Parse results ---
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
VULNS=""

case "$PROJECT_TYPE" in
    node)
        # npm audit JSON output
        CRITICAL=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    meta = d.get('metadata', {}).get('vulnerabilities', {})
    print(meta.get('critical', 0))
except: print(0)
" 2>/dev/null || echo 0)
        HIGH=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    meta = d.get('metadata', {}).get('vulnerabilities', {})
    print(meta.get('high', 0))
except: print(0)
" 2>/dev/null || echo 0)
        MEDIUM=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    meta = d.get('metadata', {}).get('vulnerabilities', {})
    print(meta.get('moderate', meta.get('medium', 0)))
except: print(0)
" 2>/dev/null || echo 0)
        LOW=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    meta = d.get('metadata', {}).get('vulnerabilities', {})
    print(meta.get('low', 0))
except: print(0)
" 2>/dev/null || echo 0)
        ;;
    python)
        # pip-audit or safety JSON
        CRITICAL=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if isinstance(d, list):
        print(len([v for v in d if v.get('severity','').lower() in ('critical','high')]))
    else:
        print(d.get('summary', {}).get('critical', 0))
except: print(0)
" 2>/dev/null || echo 0)
        HIGH=0  # pip-audit doesn't always differentiate
        ;;
    go)
        # govulncheck output
        CRITICAL=$(echo "$OUTPUT" | grep -ci "CRITICAL" || echo 0)
        HIGH=$(echo "$OUTPUT" | grep -ci "HIGH" || echo 0)
        MEDIUM=$(echo "$OUTPUT" | grep -ci "MEDIUM" || echo 0)
        LOW=$(echo "$OUTPUT" | grep -ci "LOW" || echo 0)
        ;;
    rust)
        CRITICAL=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    vulns = d.get('vulnerabilities', {}).get('list', [])
    print(len([v for v in vulns if v.get('advisory', {}).get('cvss', 0) >= 9]))
except: print(0)
" 2>/dev/null || echo 0)
        HIGH=$(echo "$OUTPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    vulns = d.get('vulnerabilities', {}).get('list', [])
    print(len([v for v in vulns if 7 <= v.get('advisory', {}).get('cvss', 0) < 9]))
except: print(0)
" 2>/dev/null || echo 0)
        ;;
    ruby)
        CRITICAL=$(echo "$OUTPUT" | grep -ci "critical" || echo 0)
        HIGH=$(echo "$OUTPUT" | grep -ci "high" || echo 0)
        MEDIUM=$(echo "$OUTPUT" | grep -ci "medium" || echo 0)
        LOW=$(echo "$OUTPUT" | grep -ci "low" || echo 0)
        ;;
esac

# Ensure numeric
CRITICAL=${CRITICAL:-0}
HIGH=${HIGH:-0}
MEDIUM=${MEDIUM:-0}
LOW=${LOW:-0}

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

# --- Output summary ---
echo -e "${BOLD}Vulnerability Summary:${NC}"
echo -e "  ${RED}Critical:${NC} $CRITICAL"
echo -e "  ${RED}High:${NC}     $HIGH"
echo -e "  ${YELLOW}Medium:${NC}   $MEDIUM"
echo -e "  ${CYAN}Low:${NC}      $LOW"
echo -e "  ${BOLD}Total:${NC}    $TOTAL"
echo ""

if [[ $TOTAL -eq 0 ]]; then
    echo -e "${GREEN}✓ No known vulnerabilities found.${NC}"
else
    if [[ $CRITICAL -gt 0 ]]; then
        echo -e "${RED}✗ CRITICAL vulnerabilities found! Immediate action required.${NC}"
    elif [[ $HIGH -gt 0 ]]; then
        echo -e "${YELLOW}⚠ HIGH vulnerabilities found. Address before release.${NC}"
    else
        echo -e "${GREEN}✓ No critical/high vulnerabilities.${NC}"
    fi
fi

# --- Fix suggestions ---
if [[ $SHOW_FIX -eq 1 && $TOTAL -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}Fix Commands:${NC}"
    case "$PROJECT_TYPE" in
        node)
            echo -e "  ${CYAN}npm audit fix${NC}"
            echo -e "  ${CYAN}npm audit fix --force${NC} (for breaking changes)"
            ;;
        python)
            echo -e "  ${CYAN}pip-audit --fix${NC}"
            echo -e "  ${CYAN}pip install --upgrade <package>${NC}"
            ;;
        go)
            echo -e "  ${CYAN}go get -u${NC} and ${CYAN}go mod tidy${NC}"
            ;;
        rust)
            echo -e "  ${CYAN}cargo update${NC}"
            ;;
        ruby)
            echo -e "  ${CYAN}bundle update <package>${NC}"
            ;;
    esac
fi

# --- Exit code ---
if [[ $CRITICAL -gt 0 ]]; then
    exit 1
elif [[ $HIGH -gt 0 ]]; then
    exit 2
else
    exit 0
fi
