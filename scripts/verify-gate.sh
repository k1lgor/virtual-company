#!/usr/bin/env bash
# verify-gate.sh — Gate Verification Runner
# Run a verification command and log the result.
# Usage: verify-gate.sh --gate-name NAME --command "shell command" [--log results.tsv]
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
${BOLD}verify-gate.sh${NC} — Gate Verification Runner

${BOLD}USAGE:${NC}
    verify-gate.sh --gate-name NAME --command "shell command" [--log results.tsv]

${BOLD}OPTIONS:${NC}
    --gate-name NAME   Name of the gate being verified (required)
    --command CMD      Shell command to run (required)
    --log FILE         TSV log file path (optional)
    --help, -h         Show this help message

${BOLD}DESCRIPTION:${NC}
    Runs a verification command, captures exit code and output.
    If exit code is 0: PASS, else FAIL.
    Optionally logs results to a TSV file.

${BOLD}LOG FORMAT:${NC}
    timestamp | gate_name | status | exit_code | duration_ms | output_summary

${BOLD}EXIT CODES:${NC}
    Same as the verification command's exit code

${BOLD}EXAMPLE:${NC}
    verify-gate.sh --gate-name "lint" --command "eslint src/" --log gates.tsv
    verify-gate.sh --gate-name "type-check" --command "tsc --noEmit"
EOF
    exit 0
}

# --- Parse args ---
GATE_NAME=""
COMMAND=""
LOG_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gate-name) GATE_NAME="$2"; shift 2 ;;
        --command) COMMAND="$2"; shift 2 ;;
        --log) LOG_FILE="$2"; shift 2 ;;
        --help|-h) show_help ;;
        -*) echo -e "${RED}Unknown option:${NC} $1" >&2; exit 2 ;;
        *) echo -e "${RED}Unexpected argument:${NC} $1" >&2; exit 2 ;;
    esac
done

# --- Validate ---
if [[ -z "$GATE_NAME" ]]; then
    echo -e "${RED}ERROR${NC}: --gate-name is required" >&2
    exit 2
fi

if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}ERROR${NC}: --command is required" >&2
    exit 2
fi

# --- Run the verification command ---
echo -e "${BOLD}Gate:${NC} ${CYAN}$GATE_NAME${NC}"
echo -e "${BOLD}Command:${NC} $COMMAND"
echo ""

START_MS=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")

OUTPUT=$(eval "$COMMAND" 2>&1) || true
EXIT_CODE=$?

END_MS=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
DURATION_MS=$((END_MS - START_MS))

# --- Determine status ---
if [[ $EXIT_CODE -eq 0 ]]; then
    STATUS="PASS"
    STATUS_COLOR="${GREEN}PASS${NC}"
else
    STATUS="FAIL"
    STATUS_COLOR="${RED}FAIL${NC}"
fi

# --- Truncate output to 500 chars ---
OUTPUT_SUMMARY=$(echo "$OUTPUT" | head -c 500)
if [[ ${#OUTPUT} -gt 500 ]]; then
    OUTPUT_SUMMARY="${OUTPUT_SUMMARY}...[truncated]"
fi

# --- Output ---
echo -e "${BOLD}Result:${NC} $STATUS_COLOR"
echo -e "${BOLD}Exit Code:${NC} $EXIT_CODE"
echo -e "${BOLD}Duration:${NC} ${DURATION_MS}ms"
echo ""
echo -e "${BOLD}Evidence:${NC}"
echo "---"
echo "$OUTPUT_SUMMARY"
echo "---"

# --- Log to TSV ---
if [[ -n "$LOG_FILE" ]]; then
    # Create header if file doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        echo -e "timestamp\tgate_name\tstatus\texit_code\tduration_ms\toutput_summary" > "$LOG_FILE"
    fi
    # Escape tabs and newlines in output summary for TSV
    TSV_SUMMARY=$(echo "$OUTPUT_SUMMARY" | tr '\n' ' ' | tr '\t' ' ' | head -c 200)
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo -e "${TIMESTAMP}\t${GATE_NAME}\t${STATUS}\t${EXIT_CODE}\t${DURATION_MS}\t${TSV_SUMMARY}" >> "$LOG_FILE"
    echo ""
    echo -e "${YELLOW}Logged to:${NC} $LOG_FILE"
fi

# --- Exit with same code as command ---
exit $EXIT_CODE
