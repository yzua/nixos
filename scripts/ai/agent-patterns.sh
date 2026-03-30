#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agent-logs}"

print_info "Analyzing error patterns..."
echo "----------------------------------------------------------------"

if compgen -G "$LOG_DIR/*-errors-*.log" >/dev/null; then
	cat "$LOG_DIR"/*-errors-*.log 2>/dev/null |
		grep -oE "(Error|ERROR|error|Exception|EXCEPTION|failed|Failed|FAILED):? [^[:space:]]{0,100}" |
		sort | uniq -c | sort -rn | head -20
else
	print_warning "No error log files found."
fi

echo ""
echo "----------------------------------------------------------------"
print_info "Top exit codes:"
if compgen -G "$LOG_DIR/*.log" >/dev/null; then
	grep -h "exited with code" "$LOG_DIR"/*.log 2>/dev/null |
		grep -oE "code [0-9]+" | sort | uniq -c | sort -rn | head -10 || true
else
	print_warning "No log files found."
fi
