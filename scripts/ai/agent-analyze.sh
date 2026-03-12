#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${AI_AGENT_LOG_DIR:-$HOME/.local/share/ai-agent-logs}"

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
		sessions=$(find "$LOG_DIR" -name "$agent-*.log" -mtime -7 2>/dev/null | wc -l)
		errors=$(find "$LOG_DIR" -name "$agent-errors-*.log" -mtime -7 -exec cat {} \; 2>/dev/null | wc -l)

		if [[ "$sessions" -gt 0 || "$errors" -gt 0 ]]; then
			echo "  $agent:"
			echo "    Sessions: $sessions"
			echo "    Errors:   $errors"
			echo ""
		fi
	done

	echo "---------------------------------------------------------------"
	total_logs=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1 || echo "0")
	echo "  Total log size: $total_logs"
	echo "---------------------------------------------------------------"
}

errors() {
	local agent
	agent="${1:-*}"
	echo "Recent errors for: $agent"
	echo "---------------------------------------------------------------"

	find "$LOG_DIR" -name "$agent-errors-*.log" -mtime -7 -exec sh -c '
    echo "File: $1"
    tail -20 "$1"
    echo ""
  ' _ {} \; 2>/dev/null | head -100
}

sessions() {
	echo "Session Activity Timeline (Last 24h)"
	echo "---------------------------------------------------------------"

	find "$LOG_DIR" -name "*.log" ! -name "*-errors-*" -mtime -1 -exec sh -c '
    basename "$1" .log | sed "s/-[0-9]*-[0-9]*-[0-9]*$//"
  ' _ {} \; 2>/dev/null | sort | uniq -c | sort -rn | head -20
}

search_logs() {
	local term
	term="$1"
	echo "Searching for: $term"
	echo "---------------------------------------------------------------"

	grep -rn --color=always "$term" "$LOG_DIR" 2>/dev/null | head -50
}

tail_logs() {
	local agent
	agent="${1:-*}"
	echo "Tailing logs for: $agent (Ctrl+C to stop)"
	echo "---------------------------------------------------------------"

	tail -f "$LOG_DIR"/"$agent"-*.log 2>/dev/null
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
		count=$(find "$LOG_DIR" -name "$agent-errors-*.log" -mtime -1 -exec cat {} \; 2>/dev/null | wc -l)
		if [[ "$count" -gt 0 ]]; then
			echo "  $agent: $count errors"
		fi
	done
	echo ""

	echo "Most Recent Errors:"
	find "$LOG_DIR" -name "*-errors-*.log" -mtime -1 -exec tail -5 {} \; 2>/dev/null | head -20
}

case "${1:-help}" in
stats) stats ;;
errors) errors "${2:-}" ;;
sessions) sessions ;;
search) search_logs "${2:?Search term required}" ;;
tail) tail_logs "${2:-}" ;;
report) report ;;
*) usage ;;
esac
