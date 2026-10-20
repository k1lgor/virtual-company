#!/usr/bin/env bash
# load-learnings.sh — Print recent project learnings at session start.
# Companion to log-learning.sh. Invoked by the SessionStart hook so that
# durable learnings actually reach the agent, instead of being silently
# collected and never read.
#
# Usage: load-learnings.sh [--lines N]
set -euo pipefail

LINES=5
if [[ "${1:-}" == "--lines" && -n "${2:-}" ]]; then
    LINES="$2"
fi

PROJECT_SLUG=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
LEARNINGS_FILE="${HOME}/.virtual-company/projects/${PROJECT_SLUG}/learnings.jsonl"

# Nothing logged yet — stay silent rather than printing an empty banner.
[[ -f "$LEARNINGS_FILE" ]] || exit 0

echo "--- Recent Project Learnings (last ${LINES}) ---"
tail -n "$LINES" "$LEARNINGS_FILE"
echo "---"
