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
	if [[ -z "$val" || "$val" == "null" ]]; then
		printf "?"
		return
	fi
	if ((val >= 1000000)); then
		printf "%.1fM" "$(echo "$val / 1000000" | bc -l)"
	elif ((val >= 1000)); then
		printf "%.0fK" "$(echo "$val / 1000" | bc -l)"
	else
		printf "%s" "$val"
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

read_cache() {
	local f="${CACHE_DIR}/${1}.json"
	if [[ -f "$f" ]]; then
		local age=$(($(date +%s) - $(stat -c %Y "$f")))
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

fetch_zai() {
	if [[ ! -f "$ZAI_KEY_FILE" ]]; then
		output_error "Z.ai: key not found"
		return
	fi
	local zai_key response
	zai_key=$(cat "$ZAI_KEY_FILE")

	if ! response=$(read_cache "zai"); then
		response=$(curl -s -m 8 -f "$ZAI_ENDPOINT" \
			-H "Authorization: Bearer ${zai_key}" \
			-H "Content-Type: application/json" 2>/dev/null) || response=""
		[[ -n "$response" ]] && write_cache "zai" "$response"
	fi
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
	remaining=$(printf "%.0f" "$(echo "100 - $pct" | bc -l)")
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
	if ! response=$(read_cache "claude"); then
		response=$(curl -s -m 8 -f "$CLAUDE_ENDPOINT" \
			-H "Authorization: Bearer ${token}" \
			-H "anthropic-version: 2023-06-01" \
			-H "anthropic-beta: oauth-2025-04-20" 2>/dev/null) || response=""
		[[ -n "$response" ]] && write_cache "claude" "$response"
	fi
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

	local five_int remaining
	five_int=$(printf "%.0f" "$five_h")
	remaining=$((100 - five_int))
	local color
	color=$(remaining_color "$remaining")

	local tip
	tip="<b>Claude Max (20x)</b> <span style='color:${color}'><b>${remaining}% left</b></span>"
	tip+="${NL}<tt>Left: [$(progress_bar "$remaining")] ${remaining}%</tt>"
	tip+="${NL}5h used: $(printf "%.1f" "$five_h")%"
	if [[ -n "$five_h_reset" && "$five_h_reset" != "null" ]]; then
		local epoch
		epoch=$(date -d "$five_h_reset" +%s 2>/dev/null) || true
		[[ -n "$epoch" ]] && tip+=" | Reset: $(time_until "$epoch")"
	fi
	if [[ -n "$seven_d" ]]; then
		local sd_int=$(($(printf "%.0f" "$seven_d")))
		tip+="${NL}7d used: $(printf "%.1f" "$seven_d")% (left $((100 - sd_int))%)"
	fi

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

	local five_int remaining
	five_int=$(printf "%.0f" "$five_h")
	remaining=$((100 - five_int))
	local color
	color=$(remaining_color "$remaining")

	local tip
	tip="<b>OpenAI Codex</b> <span style='color:${color}'><b>${remaining}% left</b></span>"
	tip+="${NL}<tt>Left: [$(progress_bar "$remaining")] ${remaining}%</tt>"
	tip+="${NL}5h used: $(printf "%.1f" "$five_h")%"
	if [[ "$five_h_reset" =~ ^[0-9]+$ ]]; then
		tip+=" | Reset: $(time_until "$five_h_reset")"
	fi
	if [[ -n "$seven_d" ]]; then
		local sd_int
		sd_int=$(printf "%.0f" "$seven_d")
		tip+="${NL}7d used: $(printf "%.1f" "$seven_d")% (left $((100 - sd_int))%)"
	fi

	jq -c -n --arg pct "$remaining" --arg tip "$tip" '{"pct":$pct,"tip":$tip}'
}

zai_json=$(fetch_zai)
claude_json=$(fetch_claude)
codex_json=$(fetch_codex)

zai_pct=$(echo "$zai_json" | jq -r '.pct')
claude_pct=$(echo "$claude_json" | jq -r '.pct')
codex_pct=$(echo "$codex_json" | jq -r '.pct')
zai_tip=$(echo "$zai_json" | jq -r '.tip')
claude_tip=$(echo "$claude_json" | jq -r '.tip')
codex_tip=$(echo "$codex_json" | jq -r '.tip')

icon="activity"
for pct in "$zai_pct" "$claude_pct" "$codex_pct"; do
	if [[ "$pct" =~ ^[0-9]+$ ]]; then
		if ((pct <= 20)); then
			icon="alert-triangle"
			break
		elif ((pct <= 40)); then icon="alert-circle"; fi
	fi
done

tooltip="${zai_tip}${NL}${NL}${claude_tip}${NL}${NL}${codex_tip}${NL}${NL}<span style='color:#a89984'>Updated: $(date +%H:%M)</span>"

# Wrap in left-aligned HTML — Noctalia tooltip defaults to centered text
tooltip="<p align='left'>${tooltip}</p>"

# Single-line JSON output — critical for Noctalia parseJson (multi-line breaks parser)
jq -c -n --arg icon "$icon" --arg tooltip "$tooltip" '{"text":"","icon":$icon,"tooltip":$tooltip}'
