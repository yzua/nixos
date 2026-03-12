#!/usr/bin/env bash
# Provider fetchers for api-quota widget.

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
