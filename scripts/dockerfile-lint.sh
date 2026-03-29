#!/usr/bin/env bash
# dockerfile-lint.sh — Dockerfile Best Practices Checker
# Validate Dockerfiles against security and best practice rules.
# Usage: dockerfile-lint.sh [Dockerfile path]
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
${BOLD}dockerfile-lint.sh${NC} — Dockerfile Best Practices Checker

${BOLD}USAGE:${NC}
    dockerfile-lint.sh [Dockerfile path]

${BOLD}ARGUMENTS:${NC}
    Dockerfile path    Path to Dockerfile (default: ./Dockerfile)

${BOLD}RULES (10 max):${NC}
    1. Has USER instruction (not running as root)
    2. Has HEALTHCHECK instruction
    3. Uses multi-stage build (multiple FROM statements)
    4. No COPY . . or ADD . . (too broad)
    5. No EXPOSE of privileged ports (<1024)
    6. Uses specific base image tags (not :latest)
    7. No RUN with apt-get upgrade
    8. Has LABEL maintainer or metadata
    9. No secrets in ENV or ARG defaults
    10. Uses .dockerignore

${BOLD}EXIT CODES:${NC}
    0 = score >= 8 (PASS)
    1 = score < 8 (FAIL)

${BOLD}EXAMPLE:${NC}
    dockerfile-lint.sh
    dockerfile-lint.sh ./deploy/Dockerfile.prod
EOF
    exit 0
}

# --- Parse args ---
DOCKERFILE="${1:-./Dockerfile}"

if [[ "$DOCKERFILE" == "--help" || "$DOCKERFILE" == "-h" ]]; then
    show_help
fi

if [[ ! -f "$DOCKERFILE" ]]; then
    echo -e "${RED}ERROR${NC}: Dockerfile not found: $DOCKERFILE" >&2
    exit 2
fi

SCORE=0
VIOLATIONS=()
DOCKERFILE_DIR=$(dirname "$DOCKERFILE")

# --- Rule 1: Has USER instruction ---
if grep -qE '^\s*USER\s+' "$DOCKERFILE"; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("No USER instruction (running as root)")
fi

# --- Rule 2: Has HEALTHCHECK ---
if grep -qE '^\s*HEALTHCHECK\s+' "$DOCKERFILE"; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("No HEALTHCHECK instruction")
fi

# --- Rule 3: Multi-stage build ---
FROM_COUNT=$(grep -ciE '^\s*FROM\s+' "$DOCKERFILE" || echo 0)
if [[ $FROM_COUNT -ge 2 ]]; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("Not a multi-stage build (only $FROM_COUNT FROM statement(s))")
fi

# --- Rule 4: No COPY . . or ADD . . ---
BROAD_COPY=$(grep -nE '^\s*(COPY|ADD)\s+\.\s+\.' "$DOCKERFILE" 2>/dev/null || true)
if [[ -z "$BROAD_COPY" ]]; then
    SCORE=$((SCORE + 1))
else
    LINE=$(echo "$BROAD_COPY" | head -1 | cut -d: -f1)
    VIOLATIONS+=("Broad COPY/ADD (line $LINE): copies entire context")
fi

# --- Rule 5: No privileged ports in EXPOSE ---
PRIVILEGED=$(grep -nE '^\s*EXPOSE\s+' "$DOCKERFILE" | grep -oE 'EXPOSE\s+.*' | grep -oE '\b([0-9]+)\b' | awk '$1 < 1024 {print}' || true)
if [[ -z "$PRIVILEGED" ]]; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("EXPOSE of privileged port(s): $PRIVILEGED")
fi

# --- Rule 6: Specific base image tags ---
LATEST_COUNT=$(grep -cE '^\s*FROM\s+.*:latest' "$DOCKERFILE" 2>/dev/null || echo 0)
UNTAGGED=$(grep -cE '^\s*FROM\s+[^:@[:space:]]+[[:space:]]*$' "$DOCKERFILE" 2>/dev/null || echo 0)
if [[ $LATEST_COUNT -eq 0 && $UNTAGGED -eq 0 ]]; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("Uses :latest or untagged base images")
fi

# --- Rule 7: No apt-get upgrade ---
APT_UPGRADE=$(grep -nE 'apt-get\s+.*upgrade' "$DOCKERFILE" 2>/dev/null || true)
if [[ -z "$APT_UPGRADE" ]]; then
    SCORE=$((SCORE + 1))
else
    LINE=$(echo "$APT_UPGRADE" | head -1 | cut -d: -f1)
    VIOLATIONS+=("Uses apt-get upgrade (line $LINE) — use specific package versions")
fi

# --- Rule 8: Has LABEL ---
if grep -qE '^\s*LABEL\s+' "$DOCKERFILE"; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("No LABEL instruction for metadata")
fi

# --- Rule 9: No secrets in ENV/ARG ---
SECRET_ENV=$(grep -nE '^\s*(ENV|ARG)\s+.*(PASSWORD|SECRET|TOKEN|KEY|PRIVATE|CREDENTIAL).*=' "$DOCKERFILE" 2>/dev/null || true)
if [[ -z "$SECRET_ENV" ]]; then
    SCORE=$((SCORE + 1))
else
    LINE=$(echo "$SECRET_ENV" | head -1 | cut -d: -f1)
    VIOLATIONS+=("Possible secret in ENV/ARG (line $LINE)")
fi

# --- Rule 10: Has .dockerignore ---
if [[ -f "$DOCKERFILE_DIR/.dockerignore" ]]; then
    SCORE=$((SCORE + 1))
else
    VIOLATIONS+=("No .dockerignore file found in $DOCKERFILE_DIR/")
fi

# --- Output ---
echo -e "${BOLD}=== Dockerfile Linter ===${NC}"
echo -e "File: ${CYAN}$DOCKERFILE${NC}"
echo ""

if [[ $SCORE -ge 8 ]]; then
    echo -e "Score: ${GREEN}${SCORE}/10${NC} ${GREEN}PASS${NC}"
else
    echo -e "Score: ${RED}${SCORE}/10${NC} ${RED}FAIL${NC}"
fi

echo ""

if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Violations:${NC}"
    for v in "${VIOLATIONS[@]}"; do
        echo -e "  ${RED}✗${NC} $v"
    done
    echo ""
fi

# --- Exit code ---
if [[ $SCORE -ge 8 ]]; then
    exit 0
else
    exit 1
fi
