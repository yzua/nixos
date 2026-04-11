#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agents/logs}"
OPENCODE_LOG_DIR="${OPENCODE_LOG_DIR:-$HOME/.local/share/opencode/log}"
CODEX_LOG_DIR="${CODEX_LOG_DIR:-$HOME/.codex/log}"
ERROR_PATTERN='\b(error|panic|fatal|exception|failed|invalid|deprecated|certificate|ssl|tls)\b'

find_logs() {
	local agent="$1"
	local max_depth_args=()
	local -a roots=()

	case "$agent" in
	claude)
		roots+=("$LOG_DIR")
		;;
	opencode)
		roots+=("$LOG_DIR" "$OPENCODE_LOG_DIR")
		;;
	codex)
		roots+=("$LOG_DIR" "$CODEX_LOG_DIR")
		;;
	gemini)
		roots+=("$LOG_DIR")
		;;
	*)
		return 0
		;;
	esac

	local root
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

find_all_logs() {
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

count_errors() {
	local agent="$1"
	local count=0
	local file
	local matches

	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		case "$agent" in
		claude | gemini)
			matches="$(rg -i -c "$ERROR_PATTERN" "$file" 2>/dev/null || true)"
			;;
		opencode)
			matches="$(rg -i -c "$ERROR_PATTERN" "$file" 2>/dev/null || true)"
			;;
		codex)
			matches="$(rg -i -c "$ERROR_PATTERN| WARN | ERROR " "$file" 2>/dev/null || true)"
			;;
		esac
		matches="${matches:-0}"
		count=$((count + matches))
	done < <(find_logs "$agent")

	echo "$count"
}

usage() {
	echo "AI Agent Log Analyzer"
	echo ""
	echo "Usage: ai-agent-analyze <command> [options]"
	echo ""
	echo "Commands:"
	echo "  stats           Show statistics for all agents"
	echo "  errors [agent]  Show recent errors (optionally filter by agent)"
	echo "  sessions        Show session activity timeline"
	echo "  search <term>   Search logs for a term"
	echo "  tail [agent]    Live tail logs (optionally filter by agent)"
	echo "  report          Generate daily report"
	echo ""
	echo "Agents: claude, opencode, codex, gemini"
}

stats() {
	echo "---------------------------------------------------------------"
	echo "  AI Agent Statistics (Last 7 Days)"
	echo "---------------------------------------------------------------"
	echo ""

	for agent in claude opencode codex gemini; do
		sessions=$(find_logs "$agent" | wc -l)
		errors=$(count_errors "$agent")

		if [[ "$sessions" -gt 0 || "$errors" -gt 0 ]]; then
			echo "  $agent:"
			echo "    Sessions: $sessions"
			echo "    Errors:   $errors"
			echo ""
		fi
	done

	echo "---------------------------------------------------------------"
	total_logs=$(du -sch "$LOG_DIR" "$OPENCODE_LOG_DIR" "$CODEX_LOG_DIR" 2>/dev/null | awk '/total$/ {print $1}' | tail -n1)
	total_logs="${total_logs:-0}"
	echo "  Total log size: $total_logs"
	echo "---------------------------------------------------------------"
}

errors() {
	local agent
	agent="${1:-*}"
	echo "Recent errors for: $agent"
	echo "---------------------------------------------------------------"

	if [[ "$agent" == "*" ]]; then
		find_all_logs | xargs -r rg -n -i "$ERROR_PATTERN" 2>/dev/null | tail -100
	else
		find_logs "$agent" | while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			rg -n -i "$ERROR_PATTERN" "$file" 2>/dev/null || true
		done | tail -100
	fi
}

sessions() {
	echo "Session Activity Timeline (Last 24h)"
	echo "---------------------------------------------------------------"

	{
		find "$LOG_DIR" -maxdepth 1 -name "*.log" ! -name "*-errors-*" -mtime -1 -printf '%f\n' 2>/dev/null |
			sed -E 's/-[0-9]{4}-[0-9]{2}-[0-9]{2}\.log$//'
		find "$OPENCODE_LOG_DIR" -maxdepth 1 -name "*.log" -mtime -1 -printf 'opencode\n' 2>/dev/null
		find "$CODEX_LOG_DIR" -maxdepth 1 -name "*.log" -mtime -1 -printf 'codex\n' 2>/dev/null
	} | sort | uniq -c | sort -rn | head -20
}

search_logs() {
	local term
	term="$1"
	echo "Searching for: $term"
	echo "---------------------------------------------------------------"

	find_all_logs | xargs -r rg -n --color=always "$term" 2>/dev/null | head -50
}

tail_logs() {
	local agent
	agent="${1:-*}"
	echo "Tailing logs for: $agent (Ctrl+C to stop)"
	echo "---------------------------------------------------------------"

	if [[ "$agent" == "*" ]]; then
		tail -f "$LOG_DIR"/*.log "$OPENCODE_LOG_DIR"/*.log "$CODEX_LOG_DIR"/*.log 2>/dev/null
	else
		find_logs "$agent" | xargs -r tail -f 2>/dev/null
	fi
}

report() {
	echo "---------------------------------------------------------------"
	echo "  AI Agent Daily Report - $(date +%Y-%m-%d)"
	echo "---------------------------------------------------------------"
	echo ""

	echo "Session Summary:"
	sessions
	echo ""

	echo "Error Summary:"
	for agent in claude opencode codex gemini; do
		count=$(count_errors "$agent")
		if [[ "$count" -gt 0 ]]; then
			echo "  $agent: $count errors"
		fi
	done
	echo ""

	echo "Most Recent Errors:"
	find_all_logs | xargs -r rg -n -i "$ERROR_PATTERN" 2>/dev/null | tail -20
}

case "${1:-help}" in
stats) stats ;;
errors) errors "${2:-}" ;;
sessions) sessions ;;
search) search_logs "${2:?$(print_error "Search term required")}" ;;
tail) tail_logs "${2:-}" ;;
report) report ;;
*) usage ;;
esac
