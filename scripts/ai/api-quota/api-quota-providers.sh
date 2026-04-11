#!/usr/bin/env bash
# Provider fetchers for api-quota widget.

emit_unavailable() {
	local id="$1"
	local name="$2"
	local short="$3"
	local message="$4"
	local error="$5"

	jq -c -n \
		--arg id "$id" \
		--arg name "$name" \
		--arg short "$short" \
		--arg pct "?" \
		--arg accent "#7c6f64" \
		--arg tip "$message" \
		--arg error "$error" \
		'{
			"id":$id,
			"name":$name,
			"short":$short,
			"pct":$pct,
			"accent":$accent,
			"available":false,
			"tip":$tip,
			"error":$error
		}'
}

fetch_zai() {
	if [[ ! -f "$ZAI_KEY_FILE" ]]; then
		emit_unavailable "zai" "Z.ai" "Z" "Z.ai: key not found" "Key not found"
		return
	fi

	local zai_key response
	zai_key=$(cat "$ZAI_KEY_FILE")

	response=$(fetch_cached_response "zai" "$ZAI_ENDPOINT" \
		-H "Authorization: Bearer ${zai_key}" \
		-H "Content-Type: application/json")
	[[ -z "$response" ]] && {
		emit_unavailable "zai" "Z.ai" "Z" "Z.ai: API unreachable" "API unreachable"
		return
	}

	local pct used limit reset_ms
	pct=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .percentage // empty' 2>/dev/null) || true
	used=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .currentValue // empty' 2>/dev/null) || true
	limit=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .usage // empty' 2>/dev/null) || true
	reset_ms=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TOKENS_LIMIT") | .nextResetTime // empty' 2>/dev/null) || true
	[[ -z "$pct" ]] && {
		emit_unavailable "zai" "Z.ai" "Z" "Z.ai: bad response" "Bad response"
		return
	}

	local remaining
	if ! remaining=$(numeric_pct_to_remaining "$pct"); then
		emit_unavailable "zai" "Z.ai" "Z" "Z.ai: bad response" "Bad response"
		return
	fi

	local color reset_label tip level
	color=$(remaining_color "$remaining")
	level=$(echo "$response" | jq -r '.data.level // empty' 2>/dev/null) || true
	reset_label=""
	if [[ -n "$reset_ms" && "$reset_ms" != "null" ]]; then
		reset_label="Resets in $(time_until "$((reset_ms / 1000))")"
	fi

	tip="<span style='color:#ebdbb2'><b>Z.ai GLM Coding</b></span>"
	tip+="${NL}$(status_row "Left" "${remaining}% [$(progress_bar "$remaining")]" "$color")"
	tip+="${NL}$(status_row "Used" "$(printf "%.1f%%" "$pct")" "#ebdbb2")"
	[[ -n "$reset_label" ]] && tip+="  <span style='color:#a89984'>Reset</span> ${reset_label#Resets in }"

	local mcp_used mcp_limit mcp_remaining mcp_used_pct mcp_remaining_pct tokens_value mcp_reset_ms mcp_reset_label usage_breakdown
	mcp_used=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .currentValue // empty' 2>/dev/null) || true
	mcp_limit=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .usage // empty' 2>/dev/null) || true
	mcp_remaining=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .remaining // empty' 2>/dev/null) || true
	mcp_used_pct=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .percentage // empty' 2>/dev/null) || true
	mcp_reset_ms=$(echo "$response" | jq -r '.data.limits[]? | select(.type=="TIME_LIMIT") | .nextResetTime // empty' 2>/dev/null) || true
	mcp_remaining_pct="$(numeric_pct_to_remaining "${mcp_used_pct:-0}" 2>/dev/null || true)"
	if [[ -n "$mcp_reset_ms" && "$mcp_reset_ms" != "null" ]]; then
		mcp_reset_label="Resets in $(time_until "$((mcp_reset_ms / 1000))")"
	fi
	usage_breakdown=$(echo "$response" | jq -r '
		.data.limits[]? | select(.type=="TIME_LIMIT") | .usageDetails // []
		| map("\(.modelCode) \(.usage)")
		| join(" · ")
	' 2>/dev/null) || true
	tokens_value="$(format_tokens "$used") / $(format_tokens "$limit")"
	if [[ -n "$used" && -n "$limit" ]]; then
		tip+="${NL}$(status_row "Tokens" "$tokens_value" "#ebdbb2")"
	fi
	if [[ -n "$mcp_used" && -n "$mcp_limit" ]]; then
		tip+="${NL}$(status_row "MCP" "${mcp_used}/${mcp_limit}" "#ebdbb2")"
	fi

	jq -c -n \
		--arg id "zai" \
		--arg name "Z.ai" \
		--arg short "Z" \
		--arg pct "$remaining" \
		--arg accent "$color" \
		--arg tip "$tip" \
		--arg headline "${remaining}% left" \
		--arg subtitle "GLM Coding quota" \
		--arg level "$level" \
		--arg primaryLabel "Tokens" \
		--arg primaryPct "$remaining" \
		--arg primaryValue "${remaining}% left" \
		--arg primaryMeta "$reset_label" \
		--arg secondaryLabel "MCP" \
		--arg secondaryPct "${mcp_remaining_pct:-}" \
		--arg secondaryValue "${mcp_remaining:-?} left" \
		--arg secondaryMeta "${mcp_used:-?} / ${mcp_limit:-?} calls used" \
		--arg detail1 "$(printf "%.1f%% used" "$pct")" \
		--arg detail2 "$tokens_value" \
		--arg detail3 "${mcp_reset_label:-Unknown}" \
		--arg detail4 "${usage_breakdown:-No MCP calls yet}" \
		'{
			"id":$id,
			"name":$name,
			"short":$short,
			"pct":$pct,
			"accent":$accent,
			"available":true,
			"tip":$tip,
			"headline":$headline,
			"subtitle":$subtitle,
			"badges":[$level],
			"primary":{"label":$primaryLabel,"pct":$primaryPct,"value":$primaryValue,"meta":$primaryMeta},
			"secondary":{"label":$secondaryLabel,"pct":$secondaryPct,"value":$secondaryValue,"meta":$secondaryMeta},
			"details":[
				{"label":"Usage","value":$detail1},
				{"label":"Tokens","value":$detail2},
				{"label":"MCP reset","value":$detail3},
				{"label":"MCP mix","value":$detail4}
			]
		} | .badges |= map(select(. != "" and . != "null"))'
}

fetch_claude() {
	if [[ ! -f "$CLAUDE_CREDS" ]]; then
		emit_unavailable "claude" "Claude" "C" "Claude: no credentials" "No credentials"
		return
	fi

	local token expires_at
	token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CLAUDE_CREDS" 2>/dev/null) || true
	expires_at=$(jq -r '.claudeAiOauth.expiresAt // empty' "$CLAUDE_CREDS" 2>/dev/null) || true
	[[ -z "$token" ]] && {
		emit_unavailable "claude" "Claude" "C" "Claude: no OAuth token" "No OAuth token"
		return
	}

	local now_ms
	now_ms=$(($(date +%s) * 1000))
	if [[ -n "$expires_at" ]] && ((now_ms > expires_at)); then
		emit_unavailable "claude" "Claude" "C" "Claude: token expired — run claude to refresh" "Token expired"
		return
	fi

	local response
	response=$(fetch_cached_response "claude" "$CLAUDE_ENDPOINT" \
		-H "Authorization: Bearer ${token}" \
		-H "anthropic-version: 2023-06-01" \
		-H "anthropic-beta: oauth-2025-04-20")
	[[ -z "$response" ]] && {
		emit_unavailable "claude" "Claude" "C" "Claude: API unreachable" "API unreachable"
		return
	}

	local five_h five_h_reset seven_d
	five_h=$(echo "$response" | jq -r '.five_hour.utilization // empty' 2>/dev/null) || true
	five_h_reset=$(echo "$response" | jq -r '.five_hour.resets_at // empty' 2>/dev/null) || true
	seven_d=$(echo "$response" | jq -r '.seven_day.utilization // empty' 2>/dev/null) || true
	[[ -z "$five_h" ]] && {
		emit_unavailable "claude" "Claude" "C" "Claude: unexpected response" "Unexpected response"
		return
	}

	local remaining seven_remaining tip color reset_epoch reset_label
	if ! remaining=$(numeric_pct_to_remaining "$five_h"); then
		emit_unavailable "claude" "Claude" "C" "Claude: unexpected response" "Unexpected response"
		return
	fi
	tip=$(build_window_tip "Claude Max (20x)" "$five_h" "$five_h_reset" "$seven_d" "iso8601")
	color=$(remaining_color "$remaining")
	reset_label=""
	if reset_epoch=$(resolve_reset_epoch "$five_h_reset" "iso8601"); then
		reset_label="Resets in $(time_until "$reset_epoch")"
	fi
	seven_remaining="$(numeric_pct_to_remaining "$seven_d" 2>/dev/null || true)"

	jq -c -n \
		--arg id "claude" \
		--arg name "Claude" \
		--arg short "C" \
		--arg pct "$remaining" \
		--arg accent "$color" \
		--arg tip "$tip" \
		--arg headline "${remaining}% left" \
		--arg subtitle "Claude Max (20x)" \
		--arg primaryLabel "Session" \
		--arg primaryPct "$remaining" \
		--arg primaryValue "${remaining}% left" \
		--arg primaryMeta "$reset_label" \
		--arg secondaryLabel "Weekly" \
		--arg secondaryPct "$seven_remaining" \
		--arg secondaryValue "${seven_remaining:-?}% left" \
		--arg secondaryMeta "$(printf "%.1f%% used" "$seven_d")" \
		--arg detail1 "$(printf "%.1f%% used" "$five_h")" \
		--arg detail2 "$(printf "%.1f%% used" "$seven_d")" \
		'{
			"id":$id,
			"name":$name,
			"short":$short,
			"pct":$pct,
			"accent":$accent,
			"available":true,
			"tip":$tip,
			"headline":$headline,
			"subtitle":$subtitle,
			"primary":{"label":$primaryLabel,"pct":$primaryPct,"value":$primaryValue,"meta":$primaryMeta},
			"secondary":{"label":$secondaryLabel,"pct":$secondaryPct,"value":$secondaryValue,"meta":$secondaryMeta},
			"details":[
				{"label":"5h window","value":$detail1},
				{"label":"7d window","value":$detail2}
			]
		}'
}

fetch_codex() {
	if [[ ! -d "$CODEX_SESSIONS_DIR" ]]; then
		emit_unavailable "codex" "Codex" "O" "Codex: no local usage data" "No local usage data"
		return
	fi

	local payload_json=""
	local rollout_file
	while IFS= read -r rollout_file; do
		payload_json=$(jq -rc '
      select(.type=="event_msg"
        and .payload.type=="token_count"
        and .payload.rate_limits.limit_id=="codex")
      | .payload
    ' "$rollout_file" 2>/dev/null | tail -n1) || true
		[[ -n "$payload_json" ]] && break
	done < <(find "$CODEX_SESSIONS_DIR" -type f -name 'rollout-*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 12 | cut -d' ' -f2-)

	[[ -z "$payload_json" ]] && {
		emit_unavailable "codex" "Codex" "O" "Codex: no local usage data" "No local usage data"
		return
	}

	local five_h five_h_reset seven_d
	five_h=$(echo "$payload_json" | jq -r '.rate_limits.primary.used_percent // empty' 2>/dev/null) || true
	five_h_reset=$(echo "$payload_json" | jq -r '.rate_limits.primary.resets_at // empty' 2>/dev/null) || true
	seven_d=$(echo "$payload_json" | jq -r '.rate_limits.secondary.used_percent // empty' 2>/dev/null) || true
	[[ -z "$five_h" ]] && {
		emit_unavailable "codex" "Codex" "O" "Codex: unexpected local data" "Unexpected local data"
		return
	}

	local remaining seven_remaining tip color reset_label plan_type context_window total_tokens last_tokens cached_tokens reasoning_tokens
	if ! remaining=$(numeric_pct_to_remaining "$five_h"); then
		emit_unavailable "codex" "Codex" "O" "Codex: unexpected local data" "Unexpected local data"
		return
	fi
	tip=$(build_window_tip "OpenAI Codex" "$five_h" "$five_h_reset" "$seven_d" "epoch")
	color=$(remaining_color "$remaining")
	plan_type=$(echo "$payload_json" | jq -r '.rate_limits.plan_type // empty' 2>/dev/null) || true
	context_window=$(echo "$payload_json" | jq -r '.info.model_context_window // empty' 2>/dev/null) || true
	total_tokens=$(echo "$payload_json" | jq -r '.info.total_token_usage.total_tokens // empty' 2>/dev/null) || true
	last_tokens=$(echo "$payload_json" | jq -r '.info.last_token_usage.total_tokens // empty' 2>/dev/null) || true
	cached_tokens=$(echo "$payload_json" | jq -r '.info.total_token_usage.cached_input_tokens // empty' 2>/dev/null) || true
	reasoning_tokens=$(echo "$payload_json" | jq -r '.info.total_token_usage.reasoning_output_tokens // empty' 2>/dev/null) || true
	reset_label=""
	if [[ "$five_h_reset" =~ ^[0-9]+$ ]]; then
		reset_label="Resets in $(time_until "$five_h_reset")"
	fi
	seven_remaining="$(numeric_pct_to_remaining "$seven_d" 2>/dev/null || true)"

	jq -c -n \
		--arg id "codex" \
		--arg name "Codex" \
		--arg short "O" \
		--arg pct "$remaining" \
		--arg accent "$color" \
		--arg tip "$tip" \
		--arg headline "${remaining}% left" \
		--arg subtitle "OpenAI Codex" \
		--arg badge1 "${plan_type:-local}" \
		--arg badge2 "$( [[ -n "$context_window" && "$context_window" != "null" ]] && printf '%s ctx' "$(format_tokens "$context_window")" || printf '' )" \
		--arg primaryLabel "Session" \
		--arg primaryPct "$remaining" \
		--arg primaryValue "${remaining}% left" \
		--arg primaryMeta "$reset_label" \
		--arg secondaryLabel "Weekly" \
		--arg secondaryPct "$seven_remaining" \
		--arg secondaryValue "${seven_remaining:-?}% left" \
		--arg secondaryMeta "$(printf "%.1f%% used" "$seven_d")" \
		--arg detail1 "$(printf "%.1f%% used" "$five_h")" \
		--arg detail2 "$(printf "%.1f%% used" "$seven_d")" \
		--arg detail3 "$(format_tokens "$total_tokens")" \
		--arg detail4 "$(format_tokens "$last_tokens")" \
		--arg detail5 "$(format_tokens "$cached_tokens")" \
		--arg detail6 "$(format_tokens "$reasoning_tokens")" \
		'{
			"id":$id,
			"name":$name,
			"short":$short,
			"pct":$pct,
			"accent":$accent,
			"available":true,
			"tip":$tip,
			"headline":$headline,
			"subtitle":$subtitle,
			"badges":[
				$badge1,
				$badge2
			],
			"primary":{"label":$primaryLabel,"pct":$primaryPct,"value":$primaryValue,"meta":$primaryMeta},
			"secondary":{"label":$secondaryLabel,"pct":$secondaryPct,"value":$secondaryValue,"meta":$secondaryMeta},
			"details":[
				{"label":"5h window","value":$detail1},
				{"label":"7d window","value":$detail2},
				{"label":"Total tokens","value":$detail3},
				{"label":"Last turn","value":$detail4},
				{"label":"Cached input","value":$detail5},
				{"label":"Reasoning","value":$detail6}
			]
		} | .badges |= map(select(. != "" and . != "null"))'
}
