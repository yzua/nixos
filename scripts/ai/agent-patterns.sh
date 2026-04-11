#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
OPENCODE_LOG_DIR="${OPENCODE_LOG_DIR:-$HOME/.local/share/opencode/log}"
CODEX_LOG_DIR="${CODEX_LOG_DIR:-$HOME/.codex/log}"

find_recent_logs() {
	local root
	local -a roots=("$LOG_DIR" "$OPENCODE_LOG_DIR" "$CODEX_LOG_DIR")
	local max_depth_args=()

	for root in "${roots[@]}"; do
		[[ -d "$root" ]] || continue
		if [[ "$root" == "$LOG_DIR" ]]; then
			max_depth_args=(-maxdepth 1)
		else
			max_depth_args=()
		fi
		find "$root" "${max_depth_args[@]}" -type f -name '*.log' -mtime -7 2>/dev/null
	done | sort -u
}

print_info "Analyzing error patterns..."
echo "----------------------------------------------------------------"

if find_recent_logs | grep -q .; then
	find_recent_logs | xargs -r rg --no-filename -o -i '\b(error|exception|failed|panic|fatal|invalid|deprecated|certificate|ssl|tls)\b:? .{0,120}' 2>/dev/null |
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
