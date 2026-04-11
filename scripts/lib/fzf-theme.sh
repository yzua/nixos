#!/usr/bin/env bash
# Shared FZF theme initialization for scripts run outside interactive shells.
# Sources: Home Manager session vars first, then Gruvbox fallback.
#
# Usage: source "$(dirname "$0")/../lib/fzf-theme.sh"

# Ensure fzf inherits Home Manager theme when launched outside interactive shells.
if [[ -z "${FZF_DEFAULT_OPTS:-}" ]] && [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
	# shellcheck disable=SC1091
	source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
	export FZF_DEFAULT_OPTS="--color=fg:#ebdbb2,bg:#32302f,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#8ec07c,prompt:#83a598,pointer:#fe8019,marker:#b8bb26,spinner:#d3869b,header:#928374,border:#504945,gutter:#282828"
fi
