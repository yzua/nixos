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
# shellcheck disable=SC2034 # Shared newline separator consumed by sourced helpers/providers.
NL=$'\n'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/api-quota-helpers.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/api-quota-providers.sh"

collect_data() {
	local zai_json claude_json codex_json
	zai_json=$(fetch_zai)
	claude_json=$(fetch_claude)
	codex_json=$(fetch_codex)

	local zai_pct claude_pct codex_pct
	zai_pct=$(echo "$zai_json" | jq -r '.pct')
	claude_pct=$(echo "$claude_json" | jq -r '.pct')
	codex_pct=$(echo "$codex_json" | jq -r '.pct')

	local icon="activity"
	local accent="#83a598"
	local pct
	for pct in "$zai_pct" "$claude_pct" "$codex_pct"; do
		if [[ "$pct" =~ ^[0-9]+$ ]]; then
			if ((pct <= 20)); then
				icon="alert-triangle"
				accent="#fb4934"
				break
			elif ((pct <= 40)); then
				icon="alert-circle"
				accent="#fabd2f"
			fi
		fi
	done

	jq -c -n \
		--argjson zai "$zai_json" \
		--argjson claude "$claude_json" \
		--argjson codex "$codex_json" \
		--arg summary "$(build_status_text "$zai_pct" "$claude_pct" "$codex_pct")" \
		--arg updated "$(date +%H:%M)" \
		--arg updatedEpoch "$(date +%s)" \
		--arg icon "$icon" \
		--arg accent "$accent" \
		'{
			"summary":$summary,
			"updatedLabel":("Updated " + $updated),
			"updatedEpoch":($updatedEpoch | tonumber),
			"icon":$icon,
			"accent":$accent,
			"providers":[$codex, $claude, $zai]
		}'
}

render_widget() {
	local data_json
	data_json=$(collect_data)

	local text icon tooltip
	text=$(echo "$data_json" | jq -r '.summary')
	icon=$(echo "$data_json" | jq -r '.icon')
	tooltip=$(echo "$data_json" | jq -r '
		"<span style='\''color:#ebdbb2'\''><b>AI Quota</b></span>\n" +
		"<span style='\''color:#a89984'\''>" + .summary + "</span>\n\n" +
		(.providers | map(.tip) | join("\n\n")) + "\n\n" +
		"<span style='\''color:#a89984'\''>" + .updatedLabel + "</span>"
	')

	tooltip="<div align='left'>${tooltip}</div>"
	jq -c -n --arg text "$text" --arg icon "$icon" --arg tooltip "$tooltip" '{"text":$text,"icon":$icon,"tooltip":$tooltip}'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	case "${1:-widget}" in
	widget)
		render_widget
		;;
	data)
		collect_data
		;;
	*)
		echo "Usage: api-quota.sh [widget|data]" >&2
		exit 1
		;;
	esac
fi
