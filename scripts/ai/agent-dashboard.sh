#!/usr/bin/env bash
set -euo pipefail

if ! command -v fzf >/dev/null 2>&1; then
	echo "Error: fzf is required for the dashboard" >&2
	exit 1
fi

while true; do
	action=$(printf '%s\n' \
		"Stats" \
		"Errors" \
		"Sessions" \
		"Search" \
		"Tail Logs" \
		"Report" \
		"Error Patterns" \
		"Exit" | fzf --header="AI Agent Dashboard" --height=50% --reverse)

	case "$action" in
	"Stats")
		ai-agent-analyze stats
		read -r -p "Press Enter..."
		;;
	"Errors")
		ai-agent-analyze errors
		read -r -p "Press Enter..."
		;;
	"Sessions")
		ai-agent-analyze sessions
		read -r -p "Press Enter..."
		;;
	"Search")
		read -r -p "Search term: " term
		ai-agent-analyze search "$term"
		read -r -p "Press Enter..."
		;;
	"Tail Logs")
		ai-agent-analyze tail
		;;
	"Report")
		ai-agent-analyze report
		read -r -p "Press Enter..."
		;;
	"Error Patterns")
		ai-agent-patterns
		read -r -p "Press Enter..."
		;;
	"Exit" | "")
		exit 0
		;;
	esac
done
