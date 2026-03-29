#!/usr/bin/env bash
# security-sentinel.sh — Enhanced Secret Scanner
# Scans files for leaked secrets and credentials.
# Usage: security-sentinel.sh [OPTIONS] [file...]
#        echo "content" | security-sentinel.sh [OPTIONS]
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Defaults ---
OUTPUT_MODE="json"
SEVERITY_FILTER=""
FOUND_SECRETS=0
CUSTOM_PATTERNS_FILE=".secret-patterns"

# --- Help ---
show_help() {
    cat <<EOF
${BOLD}security-sentinel.sh${NC} — Enhanced Secret Scanner

${BOLD}USAGE:${NC}
    security-sentinel.sh [OPTIONS] [file...]
    echo "content" | security-sentinel.sh [OPTIONS]

${BOLD}OPTIONS:${NC}
    --json           Output as JSON (default)
    --text           Output as human-readable text
    --severity LEVEL Filter results by severity (CRITICAL, HIGH, MEDIUM)
    --help, -h       Show this help message

${BOLD}SUPPORTED PATTERNS:${NC}
    Google API keys, OpenAI keys, GitHub tokens, AWS keys,
    Generic passwords, Private keys, JWT tokens, Slack tokens,
    Stripe keys, Twilio, SendGRID, Heroku, npm tokens

${BOLD}CUSTOM PATTERNS:${NC}
    Create a .secret-patterns file with one regex per line (# comments)

${BOLD}EXIT CODES:${NC}
    0 = no secrets found
    1 = secrets found

${BOLD}EXAMPLE:${NC}
    security-sentinel.sh --text src/config.js
    find . -name "*.env" | security-sentinel.sh --json
EOF
    exit 0
}

# --- Parse args ---
FILES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) OUTPUT_MODE="json"; shift ;;
        --text) OUTPUT_MODE="text"; shift ;;
        --severity) SEVERITY_FILTER="$2"; shift 2 ;;
        --help|-h) show_help ;;
        -*) echo -e "${RED}Unknown option:${NC} $1" >&2; exit 2 ;;
        *) FILES+=("$1"); shift ;;
    esac
done

# --- Pattern definitions ---
# Each pattern: "name|severity|regex"
PATTERNS=(
    "Google API Key|CRITICAL|AIza[0-9A-Za-z_-]\{35\}"
    "OpenAI API Key|CRITICAL|sk-[a-zA-Z0-9]\{48\}"
    "GitHub Token (ghp)|CRITICAL|ghp_[a-zA-Z0-9]\{36\}"
    "GitHub Token (gho)|CRITICAL|gho_[a-zA-Z0-9]\{36\}"
    "GitHub Token (ghu)|CRITICAL|ghu_[a-zA-Z0-9]\{36\}"
    "GitHub Token (ghs)|CRITICAL|ghs_[a-zA-Z0-9]\{36\}"
    "GitHub Token (ghr)|CRITICAL|ghr_[a-zA-Z0-9]\{36\}"
    "AWS Access Key|CRITICAL|AKIA[0-9A-Z]\{16\}"
    "Private Key|CRITICAL|-----BEGIN \(RSA \|EC \|DSA \)\{0,1\}PRIVATE KEY-----"
    "Stripe Live Key (sk)|CRITICAL|sk_live_[0-9a-zA-Z]\{24,\}"
    "Stripe Live Key (rk)|CRITICAL|rk_live_[0-9a-zA-Z]\{24,\}"
    "npm Token|HIGH|npm_[A-Za-z0-9]\{36\}"
    "Slack Token|HIGH|xox[bpqoras]-[0-9a-zA-Z-]\+"
    "Twilio API Key|HIGH|SK[0-9a-fA-F]\{32\}"
    "SendGRID API Key|HIGH|SG\.[a-zA-Z0-9_-]\{22\}\.[a-zA-Z0-9_-]\{43\}"
    "JWT Token|HIGH|eyJ[a-zA-Z0-9_-]\+\.eyJ[a-zA-Z0-9_-]\+\.[a-zA-Z0-9_-]\+"
    "Generic Password|MEDIUM|password[[:space:]]*=[[:space:]]*[\"'][^\"']\+[\"']"
    "Heroku API Key|MEDIUM|[0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{12\}"
)

# --- Load custom patterns ---
if [[ -f "$CUSTOM_PATTERNS_FILE" ]]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        PATTERNS+=("Custom Pattern|MEDIUM|$line")
    done < "$CUSTOM_PATTERNS_FILE"
fi

# --- Severity filter helper ---
severity_rank() {
    case "$1" in
        CRITICAL) echo 3 ;;
        HIGH) echo 2 ;;
        MEDIUM) echo 1 ;;
        *) echo 0 ;;
    esac
}

should_report() {
    local sev="$1"
    if [[ -z "$SEVERITY_FILTER" ]]; then
        return 0
    fi
    local filter_rank=$(severity_rank "$SEVERITY_FILTER")
    local sev_rank=$(severity_rank "$sev")
    [[ $sev_rank -ge $filter_rank ]]
}

# --- Scanning function ---
scan_file() {
    local file="$1"
    [[ ! -f "$file" ]] && return

    for pattern_def in "${PATTERNS[@]}"; do
        IFS='|' read -r name severity regex <<< "$pattern_def"

        # Skip if severity filter doesn't match
        if ! should_report "$severity"; then
            continue
        fi

        # Use grep with the regex pattern
        local matches
        matches=$(grep -nE "$regex" "$file" 2>/dev/null || true)

        if [[ -n "$matches" ]]; then
            FOUND_SECRETS=1
            echo "$matches" | while IFS= read -r match; do
                local line_num="${match%%:*}"
                local content="${match#*:}"
                # Mask the secret (show first 4 and last 4 chars)
                local masked
                masked=$(echo "$content" | sed -E 's/([A-Za-z0-9]{4})[A-Za-z0-9_-]+([A-Za-z0-9]{4})/\1****\2/g')

                if [[ "$OUTPUT_MODE" == "json" ]]; then
                    printf '{"file":"%s","line":%d,"pattern_name":"%s","severity":"%s","evidence":"%s"}\n' \
                        "$file" "$line_num" "$name" "$severity" "$masked"
                else
                    echo -e "${RED}FOUND${NC} ${BOLD}$severity${NC} — $name"
                    echo -e "  File: ${CYAN}$file${NC}:${line_num}"
                    echo -e "  Evidence: $masked"
                    echo ""
                fi
            done
        fi
    done
}

# --- Main ---
if [[ ${#FILES[@]} -gt 0 ]]; then
    for f in "${FILES[@]}"; do
        scan_file "$f"
    done
else
    # Read from stdin
    TMPFILE=$(mktemp)
    trap "rm -f $TMPFILE" EXIT
    cat > "$TMPFILE"
    scan_file "$TMPFILE"
fi

# --- Exit code ---
if [[ $FOUND_SECRETS -eq 0 ]]; then
    if [[ "$OUTPUT_MODE" == "text" ]]; then
        echo -e "${GREEN}No secrets found.${NC}"
    fi
    exit 0
else
    exit 1
fi
