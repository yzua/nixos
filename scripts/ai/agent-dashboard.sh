#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

# Ensure fzf inherits Home Manager theme when launched outside interactive shells.
if [[ -z "${FZF_DEFAULT_OPTS:-}" ]] && [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
	# shellcheck disable=SC1091
	source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
	export FZF_DEFAULT_OPTS="--color=fg:#ebdbb2,bg:#32302f,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#8ec07c,prompt:#83a598,pointer:#fe8019,marker:#b8bb26,spinner:#d3869b,header:#928374,border:#504945,gutter:#282828"
fi

if ! command -v fzf >/dev/null 2>&1; then
	print_error "fzf is required for the dashboard"
	exit 1
fi

if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
	export FZF_DEFAULT_OPTS="--color=fg:#ebdbb2,bg:#32302f,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#8ec07c,prompt:#83a598,pointer:#fe8019,marker:#b8bb26,spinner:#d3869b,header:#928374,border:#504945,gutter:#282828"
fi

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
