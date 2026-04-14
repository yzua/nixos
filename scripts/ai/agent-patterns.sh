#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/log-dirs.sh
source "${SCRIPT_DIR}/../lib/log-dirs.sh"
# shellcheck source=scripts/lib/error-patterns.sh
source "${SCRIPT_DIR}/../lib/error-patterns.sh"

find_recent_logs() {
	find_all_agent_logs -7
}

print_info "Analyzing error patterns..."
echo "----------------------------------------------------------------"

if find_recent_logs | grep -q .; then
	find_recent_logs | xargs -r rg --no-filename -o -i "${ERROR_PATTERN}:? .{0,120}" 2>/dev/null |
		sort | uniq -c | sort -rn | head -20
else
	print_warning "No log files found."
fi

echo ""
echo "----------------------------------------------------------------"
print_info "Top exit codes:"
if find_recent_logs | grep -q .; then
	find_recent_logs | xargs -r grep -h "exited with code" 2>/dev/null |
		grep -oE "code [0-9]+" | sort | uniq -c | sort -rn | head -10 || true
else
	print_warning "No log files found."
fi
