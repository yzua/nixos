#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/log-dirs.sh
source "${SCRIPT_DIR}/../lib/log-dirs.sh"
# shellcheck source=scripts/lib/error-patterns.sh
source "${SCRIPT_DIR}/../lib/error-patterns.sh"

count_errors() {
	local agent="$1"
	local count=0
	local file
	local matches

	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		case "$agent" in
		claude | gemini | opencode)
			matches="$(rg -i -c "$ERROR_PATTERN" "$file" 2>/dev/null || true)"
			;;
		codex)
			matches="$(rg -i -c "$ERROR_PATTERN| WARN | ERROR " "$file" 2>/dev/null || true)"
			;;
		esac
		matches="${matches:-0}"
		count=$((count + matches))
	done < <(find_agent_logs "$agent" -7)

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
	echo "  patterns        Show error pattern frequency and top exit codes"
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
		sessions=$(find_agent_logs "$agent" -7 | wc -l)
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
		find_all_agent_logs -7 | xargs -r rg -n -i "$ERROR_PATTERN" 2>/dev/null | tail -100
	else
		find_agent_logs "$agent" -7 | while IFS= read -r file; do
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

	find_all_agent_logs -7 | xargs -r rg -n --color=always "$term" 2>/dev/null | head -50
}

tail_logs() {
	local agent
	agent="${1:-*}"
	echo "Tailing logs for: $agent (Ctrl+C to stop)"
	echo "---------------------------------------------------------------"

	if [[ "$agent" == "*" ]]; then
		find_all_agent_logs -7 | xargs -r tail -f 2>/dev/null
	else
		find_agent_logs "$agent" -7 | xargs -r tail -f 2>/dev/null
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
	find_all_agent_logs -7 | xargs -r rg -n -i "$ERROR_PATTERN" 2>/dev/null | tail -20
}

patterns() {
	print_info "Analyzing error patterns..."
	echo "----------------------------------------------------------------"

	if find_all_agent_logs -7 | grep -q .; then
		find_all_agent_logs -7 | xargs -r rg --no-filename -o -i "${ERROR_PATTERN}:? .{0,120}" 2>/dev/null |
			sort | uniq -c | sort -rn | head -20
	else
		print_warning "No log files found."
	fi

	echo ""
	echo "----------------------------------------------------------------"
	print_info "Top exit codes:"
	if find_all_agent_logs -7 | grep -q .; then
		find_all_agent_logs -7 | xargs -r grep -h "exited with code" 2>/dev/null |
			grep -oE "code [0-9]+" | sort | uniq -c | sort -rn | head -10 || true
	else
		print_warning "No log files found."
	fi
}

case "${1:-help}" in
stats) stats ;;
errors) errors "${2:-}" ;;
patterns) patterns ;;
sessions) sessions ;;
search) search_logs "${2:?$(print_error "Search term required")}" ;;
tail) tail_logs "${2:-}" ;;
report) report ;;
*) usage ;;
esac
