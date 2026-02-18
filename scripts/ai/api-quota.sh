#!/usr/bin/env bash
# api-quota.sh - Noctalia bar widget: Z.ai + Claude Max + Codex usage (parseJson mode).
set -euo pipefail

ZAI_KEY_FILE="/run/secrets/zai_api_key"
ZAI_ENDPOINT="https://api.z.ai/api/monitor/usage/quota/limit"
CLAUDE_CREDS="${HOME}/.claude/.credentials.json"
CLAUDE_ENDPOINT="https://api.anthropic.com/api/oauth/usage"
CODEX_SESSIONS_DIR="${HOME}/.codex/sessions"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/api-quota"
CACHE_TTL=120
NL=$'\n'

progress_bar() {
	local pct="$1"
	local width=12
	local fill i bar=""
	if [[ ! "$pct" =~ ^[0-9]+$ ]]; then
		printf "%s" "------------"
		return
	fi
	if ((pct < 0)); then pct=0; fi
	if ((pct > 100)); then pct=100; fi
	fill=$((pct * width / 100))
	for ((i = 0; i < fill; i++)); do bar+="#"; done
	for ((i = fill; i < width; i++)); do bar+="-"; done
	printf "%s" "$bar"
}

remaining_color() {
	local remaining="$1"
	if [[ ! "$remaining" =~ ^[0-9]+$ ]]; then
		printf "#a89984"
	elif ((remaining <= 20)); then
		printf "#fb4934"
	elif ((remaining <= 40)); then
		printf "#fabd2f"
	else
		printf "#b8bb26"
	fi
}

format_tokens() {
	local val="$1"
	local val_int
	if [[ -z "$val" || "$val" == "null" ]]; then
		printf "?"
		return
	fi
	if [[ ! "$val" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
		printf "?"
		return
	fi
	val_int=$(printf "%.0f" "$val")
	if ((val_int >= 1000000)); then
		printf "%.1fM" "$(echo "$val / 1000000" | bc -l)"
	elif ((val_int >= 1000)); then
		printf "%.0fK" "$(echo "$val / 1000" | bc -l)"
	else
		printf "%s" "$val_int"
	fi
}

time_until() {
	local now diff h m
	now=$(date +%s)
	diff=$(($1 - now))
	if ((diff <= 0)); then
		printf "now"
		return
	fi
	h=$((diff / 3600))
	m=$(((diff % 3600) / 60))
	if ((h > 0)); then printf "%dh %dm" "$h" "$m"; else printf "%dm" "$m"; fi
}

numeric_pct_to_remaining() {
	local used_pct="$1"
	local used_int
	if [[ ! "$used_pct" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
		return 1
	fi
	used_int=$(printf "%.0f" "$used_pct")
	if ((used_int < 0)); then used_int=0; fi
	if ((used_int > 100)); then used_int=100; fi
	printf "%d" "$((100 - used_int))"
}

resolve_reset_epoch() {
	local reset_value="$1"
	local reset_format="$2"
	case "$reset_format" in
	epoch)
		if [[ "$reset_value" =~ ^[0-9]+$ ]]; then
			printf "%s" "$reset_value"
			return 0
		fi
		;;
	iso8601)
		date -d "$reset_value" +%s 2>/dev/null || return 1
		return 0
		;;
	esac
	return 1
}

build_window_tip() {
	local title="$1"
	local used_pct="$2"
	local reset_value="$3"
	local seven_day_pct="$4"
	local reset_format="${5:-none}"

	local remaining color tip
	remaining=$(numeric_pct_to_remaining "$used_pct") || return 1
	color=$(remaining_color "$remaining")

	tip="<b>${title}</b> <span style='color:${color}'><b>${remaining}% left</b></span>"
	tip+="${NL}<tt>Left: [$(progress_bar "$remaining")] ${remaining}%</tt>"
	tip+="${NL}5h used: $(printf "%.1f" "$used_pct")%"

	local epoch
	if epoch=$(resolve_reset_epoch "$reset_value" "$reset_format"); then
		tip+=" | Reset: $(time_until "$epoch")"
	fi

	if [[ -n "$seven_day_pct" ]]; then
		local seven_remaining
		if seven_remaining=$(numeric_pct_to_remaining "$seven_day_pct"); then
			tip+="${NL}7d used: $(printf "%.1f" "$seven_day_pct")% (left ${seven_remaining}%)"
		fi
	fi

	printf "%s" "$tip"
}

cache_mtime_epoch() {
	local file="$1"
	stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo ""
}

read_cache() {
	local f="${CACHE_DIR}/${1}.json"
	if [[ -f "$f" ]]; then
		local mtime age
		mtime=$(cache_mtime_epoch "$f")
		if [[ -z "$mtime" ]]; then
			return 1
		fi
		age=$(($(date +%s) - mtime))
		if ((age < CACHE_TTL)); then
			cat "$f"
			return 0
		fi
	fi
	return 1
}

write_cache() {
	mkdir -p "$CACHE_DIR"
	printf '%s' "$2" >"${CACHE_DIR}/${1}.json"
}

output_error() { jq -c -n --arg tip "$1" '{"pct":"?","tip":$tip}'; }

fetch_cached_response() {
	local cache_key="$1"
	local endpoint="$2"
	shift 2

	local response
	if ! response=$(read_cache "$cache_key"); then
		response=$(curl -s -m 8 -f "$endpoint" "$@" 2>/dev/null) || response=""
		[[ -n "$response" ]] && write_cache "$cache_key" "$response"
	fi
	printf "%s" "$response"
}

fetch_zai() {
	if [[ ! -f "$ZAI_KEY_FILE" ]]; then
		output_error "Z.ai: key not found"
		return
	fi
	local zai_key response
	zai_key=$(cat "$ZAI_KEY_FILE")

	response=$(fetch_cached_response "zai" "$ZAI_ENDPOINT" \
		-H "Authorization: Bearer ${zai_key}" \
		-H "Content-Type: application/json")
	[[ -z "$response" ]] && {
		output_error "Z.ai: API unreachable"
		return
	}

	local pct used limit reset_ms
	pct=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .percentage // empty' 2>/dev/null) || true
	used=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .currentValue // empty' 2>/dev/null) || true
	limit=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .usage // empty' 2>/dev/null) || true
	reset_ms=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .nextResetTime // empty' 2>/dev/null) || true
	[[ -z "$pct" ]] && {
		output_error "Z.ai: bad response"
		return
	}

	local remaining
	if ! remaining=$(numeric_pct_to_remaining "$pct"); then
		output_error "Z.ai: bad response"
		return
	fi
	local color
	color=$(remaining_color "$remaining")

	local tip
	tip="<b>Z.ai GLM Coding</b> <span style='color:${color}'><b>${remaining}% left</b></span>"
	tip+="${NL}<tt>Left: [$(progress_bar "$remaining")] ${remaining}%</tt>"
	tip+="${NL}Used: $(printf "%.1f" "$pct")%"
	if [[ -n "$reset_ms" && "$reset_ms" != "null" ]]; then
		tip+=" | Reset: $(time_until "$((reset_ms / 1000))")"
	fi

	local mcp_used mcp_limit
	mcp_used=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .currentValue // empty' 2>/dev/null) || true
	mcp_limit=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .usage // empty' 2>/dev/null) || true
	if [[ -n "$used" && -n "$limit" ]]; then
		tip+="${NL}Tokens: $(format_tokens "$used") / $(format_tokens "$limit")"
	fi
	[[ -n "$mcp_used" && -n "$mcp_limit" ]] && tip+=" | MCP: ${mcp_used}/${mcp_limit}"

	jq -c -n --arg pct "$remaining" --arg tip "$tip" '{"pct":$pct,"tip":$tip}'
}

fetch_claude() {
	if [[ ! -f "$CLAUDE_CREDS" ]]; then
		output_error "Claude: no credentials"
		return
	fi
	local token expires_at
	token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CLAUDE_CREDS" 2>/dev/null) || true
	expires_at=$(jq -r '.claudeAiOauth.expiresAt // empty' "$CLAUDE_CREDS" 2>/dev/null) || true
	[[ -z "$token" ]] && {
		output_error "Claude: no OAuth token"
		return
	}

	local now_ms=$(($(date +%s) * 1000))
	if [[ -n "$expires_at" ]] && ((now_ms > expires_at)); then
		output_error "Claude: token expired — run claude to refresh"
		return
	fi

	local response
	response=$(fetch_cached_response "claude" "$CLAUDE_ENDPOINT" \
		-H "Authorization: Bearer ${token}" \
		-H "anthropic-version: 2023-06-01" \
		-H "anthropic-beta: oauth-2025-04-20")
	[[ -z "$response" ]] && {
		output_error "Claude: API unreachable"
		return
	}

	local five_h five_h_reset seven_d
	five_h=$(echo "$response" | jq -r '.five_hour.utilization // empty' 2>/dev/null) || true
	five_h_reset=$(echo "$response" | jq -r '.five_hour.resets_at // empty' 2>/dev/null) || true
	seven_d=$(echo "$response" | jq -r '.seven_day.utilization // empty' 2>/dev/null) || true
	[[ -z "$five_h" ]] && {
		output_error "Claude: unexpected response"
		return
	}

	local remaining tip
	if ! remaining=$(numeric_pct_to_remaining "$five_h"); then
		output_error "Claude: unexpected response"
		return
	fi
	tip=$(build_window_tip "Claude Max (20x)" "$five_h" "$five_h_reset" "$seven_d" "iso8601")

	jq -c -n --arg pct "$remaining" --arg tip "$tip" '{"pct":$pct,"tip":$tip}'
}

fetch_codex() {
	if [[ ! -d "$CODEX_SESSIONS_DIR" ]]; then
		output_error "Codex: no local usage data"
		return
	fi

	local rate_json=""
	local rollout_file
	while IFS= read -r rollout_file; do
		rate_json=$(jq -rc '
      select(.type=="event_msg"
        and .payload.type=="token_count"
        and .payload.rate_limits.limit_id=="codex")
      | .payload.rate_limits
    ' "$rollout_file" 2>/dev/null | tail -n1) || true
		[[ -n "$rate_json" ]] && break
	done < <(find "$CODEX_SESSIONS_DIR" -type f -name 'rollout-*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 12 | cut -d' ' -f2-)

	[[ -z "$rate_json" ]] && {
		output_error "Codex: no local usage data"
		return
	}

	local five_h five_h_reset seven_d
	five_h=$(echo "$rate_json" | jq -r '.primary.used_percent // empty' 2>/dev/null) || true
	five_h_reset=$(echo "$rate_json" | jq -r '.primary.resets_at // empty' 2>/dev/null) || true
	seven_d=$(echo "$rate_json" | jq -r '.secondary.used_percent // empty' 2>/dev/null) || true
	[[ -z "$five_h" ]] && {
		output_error "Codex: unexpected local data"
		return
	}

	local remaining tip
	if ! remaining=$(numeric_pct_to_remaining "$five_h"); then
		output_error "Codex: unexpected local data"
		return
	fi
	tip=$(build_window_tip "OpenAI Codex" "$five_h" "$five_h_reset" "$seven_d" "epoch")

	jq -c -n --arg pct "$remaining" --arg tip "$tip" '{"pct":$pct,"tip":$tip}'
}

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
