#!/usr/bin/env bash
# tsv-log.sh — Autoresearch TSV Logger
# Log iteration results in TSV format for autoresearch tracking.
# Usage: tsv-log.sh --iteration N --skill NAME --metric VALUE --status keep|discard|fix --description "text" [--log results.tsv]
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
${BOLD}tsv-log.sh${NC} — Autoresearch TSV Logger

${BOLD}USAGE:${NC}
    tsv-log.sh --iteration N --skill NAME --metric VALUE --status keep|discard|fix --description "text" [--log results.tsv]
    tsv-log.sh --summary [--log results.tsv]

${BOLD}OPTIONS:${NC}
    --iteration N       Iteration number (required for logging)
    --skill NAME        Skill name (required for logging)
    --metric VALUE      Metric value (numeric, required for logging)
    --status STATUS     One of: keep, discard, fix (required for logging)
    --description TEXT  Description of the result (required for logging)
    --log FILE          TSV log file path (default: results.tsv)
    --summary           Print summary of all logged results
    --help, -h          Show this help message

${BOLD}LOG FORMAT:${NC}
    iteration\ttimestamp\tskill\tmetric\tdelta\tstatus\tdescription

${BOLD}EXAMPLE:${NC}
    tsv-log.sh --iteration 3 --skill "bug-hunter" --metric 8.5 --status keep --description "Found critical bug"
    tsv-log.sh --summary
    tsv-log.sh --summary --log custom.tsv
EOF
    exit 0
}

# --- Defaults ---
LOG_FILE="results.tsv"
ITERATION=""
SKILL=""
METRIC=""
STATUS=""
DESCRIPTION=""
DO_SUMMARY=0

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --iteration) ITERATION="$2"; shift 2 ;;
        --skill) SKILL="$2"; shift 2 ;;
        --metric) METRIC="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --log) LOG_FILE="$2"; shift 2 ;;
        --summary) DO_SUMMARY=1; shift ;;
        --help|-h) show_help ;;
        -*) echo -e "${RED}Unknown option:${NC} $1" >&2; exit 2 ;;
        *) echo -e "${RED}Unexpected argument:${NC} $1" >&2; exit 2 ;;
    esac
done

# --- Summary mode ---
if [[ $DO_SUMMARY -eq 1 ]]; then
    if [[ ! -f "$LOG_FILE" ]]; then
        echo -e "${YELLOW}No log file found:${NC} $LOG_FILE"
        exit 0
    fi

    echo -e "${BOLD}=== Autoresearch Summary ===${NC}"
    echo -e "Log: ${CYAN}$LOG_FILE${NC}"
    echo ""

    # Total iterations
    TOTAL=$(tail -n +2 "$LOG_FILE" | wc -l)
    echo -e "${BOLD}Total iterations:${NC} $TOTAL"

    # Keep rate
    if [[ $TOTAL -gt 0 ]]; then
        KEEP_COUNT=$(tail -n +2 "$LOG_FILE" | awk -F'\t' '$6 == "keep"' | wc -l)
        KEEP_RATE=$(echo "scale=1; $KEEP_COUNT * 100 / $TOTAL" | bc 2>/dev/null || echo "N/A")
        echo -e "${BOLD}Keep rate:${NC} ${KEEP_COUNT}/${TOTAL} (${KEEP_RATE}%)"
    fi

    echo ""

    # Best metric per skill
    echo -e "${BOLD}Best metric per skill:${NC}"
    echo -e "${CYAN}────────────────────────────────────────${NC}"
    printf "${BOLD}%-20s %8s %8s${NC}\n" "SKILL" "BEST" "ITER"
    echo -e "${CYAN}────────────────────────────────────────${NC}"

    tail -n +2 "$LOG_FILE" | awk -F'\t' '
    {
        skill = $3
        metric = $4 + 0
        iter = $1 + 0
        if (!(skill in best) || metric > best[skill]) {
            best[skill] = metric
            best_iter[skill] = iter
        }
    }
    END {
        for (skill in best) {
            printf "%-20s %8.2f %8d\n", skill, best[skill], best_iter[skill]
        }
    }' | sort

    echo ""
    exit 0
fi

# --- Validate logging args ---
if [[ -z "$ITERATION" || -z "$SKILL" || -z "$METRIC" || -z "$STATUS" || -z "$DESCRIPTION" ]]; then
    echo -e "${RED}ERROR${NC}: --iteration, --skill, --metric, --status, and --description are required for logging" >&2
    echo "Run with --help for usage info." >&2
    exit 2
fi

# Validate status
if [[ "$STATUS" != "keep" && "$STATUS" != "discard" && "$STATUS" != "fix" ]]; then
    echo -e "${RED}ERROR${NC}: --status must be one of: keep, discard, fix" >&2
    exit 2
fi

# Validate metric is numeric
if ! echo "$METRIC" | grep -qE '^-?[0-9]+\.?[0-9]*$'; then
    echo -e "${RED}ERROR${NC}: --metric must be numeric" >&2
    exit 2
fi

# --- Create header if file doesn't exist ---
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "iteration\ttimestamp\tskill\tmetric\tdelta\tstatus\tdescription" > "$LOG_FILE"
fi

# --- Calculate delta ---
PREV_METRIC=$(tail -n +2 "$LOG_FILE" | awk -F'\t' -v skill="$SKILL" '$3 == skill {last=$4} END {print last}')
if [[ -n "$PREV_METRIC" && "$PREV_METRIC" != "" ]]; then
    DELTA=$(echo "$METRIC - $PREV_METRIC" | bc 2>/dev/null || echo "0")
else
    DELTA="0"
fi

# --- Escape description for TSV ---
DESCRIPTION_CLEAN=$(echo "$DESCRIPTION" | tr '\n' ' ' | tr '\t' ' ')

# --- Append log entry ---
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo -e "${ITERATION}\t${TIMESTAMP}\t${SKILL}\t${METRIC}\t${DELTA}\t${STATUS}\t${DESCRIPTION_CLEAN}" >> "$LOG_FILE"

echo -e "${GREEN}✓${NC} Logged iteration ${CYAN}${ITERATION}${NC} for skill ${CYAN}${SKILL}${NC}"
echo -e "  Metric: ${METRIC} (Δ${DELTA}) | Status: ${STATUS}"
