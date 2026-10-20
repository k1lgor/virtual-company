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
set +e
OUTPUT=$(eval "$AUDIT_CMD" 2>&1)
AUDIT_EXIT=$?
set -e

# --- Parse results ---
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
VULNS=""

# JSON parsing capability: jq preferred, python3 fallback. If neither exists we
# cannot read the audit output — and "cannot read" must never be reported as
# "no vulnerabilities" (the old code silently produced zeros and said "clean").
JSON_PARSER=""
if command -v jq >/dev/null 2>&1; then
    JSON_PARSER="jq"
elif command -v python3 >/dev/null 2>&1; then
    JSON_PARSER="python3"
fi

# count_json <jq-filter> <python-expression-on-d>
# Prints an integer, or FAIL when no parser is available or parsing breaks.
count_json() {
    local filter="$1" expr="$2" out=""
    case "$JSON_PARSER" in
        jq)
            out=$(printf '%s' "$OUTPUT" | jq -r "$filter" 2>/dev/null || true)
            ;;
        python3)
            out=$(printf '%s' "$OUTPUT" | python3 -c "import sys, json
try:
    d = json.load(sys.stdin)
    print(int($expr))
except Exception:
    print('FAIL')" 2>/dev/null || true)
            ;;
        *)
            out="FAIL"
            ;;
    esac
    if [[ "$out" =~ ^[0-9]+$ ]]; then
        echo "$out"
    else
        echo "FAIL"
    fi
}

case "$PROJECT_TYPE" in
    node)
        # npm audit JSON output
        CRITICAL=$(count_json '(.metadata.vulnerabilities.critical // 0)' "d.get('metadata',{}).get('vulnerabilities',{}).get('critical',0)")
        HIGH=$(count_json '(.metadata.vulnerabilities.high // 0)' "d.get('metadata',{}).get('vulnerabilities',{}).get('high',0)")
        MEDIUM=$(count_json '(.metadata.vulnerabilities.moderate // .metadata.vulnerabilities.medium // 0)' "d.get('metadata',{}).get('vulnerabilities',{}).get('moderate', d.get('metadata',{}).get('vulnerabilities',{}).get('medium',0))")
        LOW=$(count_json '(.metadata.vulnerabilities.low // 0)' "d.get('metadata',{}).get('vulnerabilities',{}).get('low',0)")
        ;;
    python)
        # pip-audit or safety JSON
        CRITICAL=$(count_json '(if type=="array" then ([.[]|select((((.severity//"")|ascii_downcase)|test("critical|high")))]|length) else (.summary.critical//0) end)' "len([v for v in d if str(v.get('severity','')).lower() in ('critical','high')]) if isinstance(d,list) else d.get('summary',{}).get('critical',0)")
        HIGH=0  # pip-audit doesn't always differentiate
        ;;
    go)
        # govulncheck output — text, so count occurrences. `grep -c` prints 0 and
        # exits 1 when there are no matches; `|| echo 0` appended a SECOND zero
        # and broke the arithmetic below.
        CRITICAL=$(printf '%s' "$OUTPUT" | grep -ci "CRITICAL" || true)
        HIGH=$(printf '%s' "$OUTPUT" | grep -ci "HIGH" || true)
        MEDIUM=$(printf '%s' "$OUTPUT" | grep -ci "MEDIUM" || true)
        LOW=$(printf '%s' "$OUTPUT" | grep -ci "LOW" || true)
        ;;
    rust)
        CRITICAL=$(count_json '[(.vulnerabilities.list//[])[]|(.advisory.cvss//0)]|map(select(.>=9))|length' "len([v for v in d.get('vulnerabilities',{}).get('list',[]) if v.get('advisory',{}).get('cvss',0)>=9])")
        HIGH=$(count_json '[(.vulnerabilities.list//[])[]|(.advisory.cvss//0)]|map(select(.>=7 and .<9))|length' "len([v for v in d.get('vulnerabilities',{}).get('list',[]) if 7<=v.get('advisory',{}).get('cvss',0)<9])")
        ;;
    ruby)
        CRITICAL=$(printf '%s' "$OUTPUT" | grep -ci "critical" || true)
        HIGH=$(printf '%s' "$OUTPUT" | grep -ci "high" || true)
        MEDIUM=$(printf '%s' "$OUTPUT" | grep -ci "medium" || true)
        LOW=$(printf '%s' "$OUTPUT" | grep -ci "low" || true)
        ;;
esac

# --- Fail closed on unparseable output ---
for v in CRITICAL HIGH MEDIUM LOW; do
    if [[ "${!v}" == "FAIL" ]]; then
        echo -e "${RED}ERROR${NC}: could not parse ${PROJECT_TYPE} audit output." >&2
        echo "Audit status is UNKNOWN — refusing to report a clean result." >&2
        if [[ -z "$JSON_PARSER" ]]; then
            echo "Install 'jq' (preferred) or 'python3' to enable audit-result parsing." >&2
        fi
        echo "Audit command exit code: ${AUDIT_EXIT}" >&2
        printf '%s\n' "$OUTPUT" | tail -20 >&2
        exit 2
    fi
done

# Ensure numeric
CRITICAL=$((CRITICAL + 0))
HIGH=$((HIGH + 0))
MEDIUM=$((MEDIUM + 0))
LOW=$((LOW + 0))

TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

# A non-zero audit exit with zero parsed findings means the tool errored, not
# that the project is clean.
if [[ $AUDIT_EXIT -ne 0 && $TOTAL -eq 0 ]]; then
    echo -e "${RED}ERROR${NC}: audit exited ${AUDIT_EXIT} but no findings were parsed." >&2
    echo "The dependency audit did not complete — result is unreliable." >&2
    printf '%s\n' "$OUTPUT" | tail -20 >&2
    exit 2
fi

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
