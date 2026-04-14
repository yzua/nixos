# shellcheck shell=bash
# Shared log directory paths and discovery for AI agent scripts.
# Source this file to get consistent log directory constants and helpers.
# Usage: source "${SCRIPT_DIR}/../lib/log-dirs.sh"

# shellcheck disable=SC2034
LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
# shellcheck disable=SC2034
OPENCODE_LOG_DIR="${OPENCODE_LOG_DIR:-$HOME/.local/share/opencode/log}"
# Codex uses the same log directory as OpenCode by default.
# Override CODEX_LOG_DIR if Codex gets its own log directory.
# shellcheck disable=SC2034
CODEX_LOG_DIR="${CODEX_LOG_DIR:-$OPENCODE_LOG_DIR}"

# Find all agent log files across standard directories.
# Args: $1 — mtime filter (default: -7, i.e. last 7 days)
# Output: sorted unique list of log file paths
find_all_agent_logs() {
	local mtime="${1:--7}"
	local root
	local -a seen_roots=()
	local max_depth_args=()

	# Deduplicate roots (CODEX_LOG_DIR may equal OPENCODE_LOG_DIR)
	for root in "$LOG_DIR" "$OPENCODE_LOG_DIR" "$CODEX_LOG_DIR"; do
		[[ -d "$root" ]] || continue
		local skip=false
		local prev
		for prev in "${seen_roots[@]}"; do
			if [[ "$root" == "$prev" ]]; then
				skip=true
				break
			fi
		done
		$skip && continue
		seen_roots+=("$root")
		if [[ "$root" == "$LOG_DIR" ]]; then
			max_depth_args=(-maxdepth 1)
		else
			max_depth_args=()
		fi
		find "$root" "${max_depth_args[@]}" -type f -name '*.log' -mtime "$mtime" 2>/dev/null
	done | sort -u
}

# Find log files for a specific agent by name.
# Args: $1 — agent name (claude, opencode, codex, gemini)
#        $2 — mtime filter (default: -7)
find_agent_logs() {
	local agent="$1"
	local mtime="${2:--7}"
	local -a roots=()

	case "$agent" in
	claude | gemini)
		roots+=("$LOG_DIR")
		;;
	opencode)
		roots+=("$LOG_DIR" "$OPENCODE_LOG_DIR")
		;;
	codex)
		roots+=("$LOG_DIR" "$CODEX_LOG_DIR")
		;;
	*)
		return 0
		;;
	esac

	local root
	local -a seen_roots=()
	local max_depth_args=()
	for root in "${roots[@]}"; do
		[[ -d "$root" ]] || continue
		local skip=false
		local prev
		for prev in "${seen_roots[@]}"; do
			if [[ "$root" == "$prev" ]]; then
				skip=true
				break
			fi
		done
		$skip && continue
		seen_roots+=("$root")
		if [[ "$root" == "$LOG_DIR" ]]; then
			max_depth_args=(-maxdepth 1)
		else
			max_depth_args=()
		fi
		find "$root" "${max_depth_args[@]}" -type f -name '*.log' -mtime "$mtime" 2>/dev/null
	done | sort -u
}
