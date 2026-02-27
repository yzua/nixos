#!/usr/bin/env bash
# api-quota.sh - Noctalia bar widget: Z.ai + Claude Max + Codex usage (parseJson mode).
set -euo pipefail

# shellcheck disable=SC2034 # Shared config constants consumed by sourced modules.
ZAI_KEY_FILE="/run/secrets/zai_api_key"
# shellcheck disable=SC2034
ZAI_ENDPOINT="https://api.z.ai/api/monitor/usage/quota/limit"
# shellcheck disable=SC2034
CLAUDE_CREDS="${HOME}/.claude/.credentials.json"
# shellcheck disable=SC2034
CLAUDE_ENDPOINT="https://api.anthropic.com/api/oauth/usage"
# shellcheck disable=SC2034
CODEX_SESSIONS_DIR="${HOME}/.codex/sessions"
# shellcheck disable=SC2034
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/api-quota"
# shellcheck disable=SC2034
CACHE_TTL=120
NL=$'\n'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/api-quota-helpers.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/api-quota-providers.sh"

main() {
	local zai_json claude_json codex_json
	zai_json=$(fetch_zai)
	claude_json=$(fetch_claude)
	codex_json=$(fetch_codex)

	local zai_pct claude_pct codex_pct zai_tip claude_tip codex_tip
	zai_pct=$(echo "$zai_json" | jq -r '.pct')
	claude_pct=$(echo "$claude_json" | jq -r '.pct')
	codex_pct=$(echo "$codex_json" | jq -r '.pct')
	zai_tip=$(echo "$zai_json" | jq -r '.tip')
	claude_tip=$(echo "$claude_json" | jq -r '.tip')
	codex_tip=$(echo "$codex_json" | jq -r '.tip')

	local icon="activity"
	local pct
	for pct in "$zai_pct" "$claude_pct" "$codex_pct"; do
		if [[ "$pct" =~ ^[0-9]+$ ]]; then
			if ((pct <= 20)); then
				icon="alert-triangle"
				break
			elif ((pct <= 40)); then icon="alert-circle"; fi
		fi
	done

	local tooltip
	tooltip="${zai_tip}${NL}${NL}${claude_tip}${NL}${NL}${codex_tip}${NL}${NL}<span style='color:#a89984'>Updated: $(date +%H:%M)</span>"

	# Wrap in left-aligned HTML — Noctalia tooltip defaults to centered text
	tooltip="<p align='left'>${tooltip}</p>"

	# Single-line JSON output — critical for Noctalia parseJson (multi-line breaks parser)
	jq -c -n --arg icon "$icon" --arg tooltip "$tooltip" '{"text":"","icon":$icon,"tooltip":$tooltip}'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
