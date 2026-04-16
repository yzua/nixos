#!/usr/bin/env bash
# Shared FZF theme initialization and generic pick helpers.
# Sources: Home Manager session vars first, then GruvboxAlt fallback.
#
# Usage: source "$(dirname "$0")/../lib/fzf-theme.sh"

# Ensure fzf inherits Home Manager theme when launched outside interactive shells.
if [[ -z "${FZF_DEFAULT_OPTS:-}" ]] && [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
	# shellcheck disable=SC1091
	source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
	export FZF_DEFAULT_OPTS="--color=fg:#ebdbb2,bg:#32302f,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#8ec07c,prompt:#83a598,pointer:#83a598,marker:#b8bb26,spinner:#d3869b,header:#928374,border:#57514e,gutter:#282828"
fi

# Pick one item from a list of arguments.
# Usage: pick "Header text" item1 item2 item3
pick() {
	local header="$1"
	shift
	printf '%s\n' "$@" | fzf --height=50% --reverse --header="$header"
}

# Pick one item from stdin (pipe-friendly).
# Usage: echo -e "foo\nbar" | pick_lines "Header text"
pick_lines() {
	local header="$1"
	fzf --height=50% --reverse --header="$header"
}
