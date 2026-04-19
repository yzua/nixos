#!/usr/bin/env bash
# _inventory-helpers.sh - Shared utility functions for agent inventory.
# Source this file after sourcing logging.sh, require.sh, and fzf-theme.sh.

# Print a TSV row: tool<TAB>kind<TAB>name<TAB>detail<TAB>source
row() {
	local tool="$1"
	local kind="$2"
	local name="$3"
	local detail="$4"
	local source="$5"
	printf '%s\t%s\t%s\t%s\t%s\n' "$tool" "$kind" "$name" "$detail" "$source"
}

# Redact sensitive tokens from piped input.
sanitize() {
	sed -E \
		-e 's/(gho_[A-Za-z0-9_]+)/[REDACTED]/g' \
		-e 's/(sk-[A-Za-z0-9_-]+)/[REDACTED]/g' \
		-e 's/(Bearer )[A-Za-z0-9._-]+/\1[REDACTED]/g'
}
export -f sanitize

# Extract keys from a JSON file using a jq expression.
# Caller must ensure jq is available (need_cmd jq).
json_keys() {
	local file="$1"
	local expr="$2"
	jq -r "$expr" "$file" 2>/dev/null || true
}

# Collect JSON keys and emit rows with a static detail string.
# Usage: collect_json_rows SCOPE KIND CONFIG_FILE JQ_KEYS_EXPR [DETAIL]
collect_json_rows() {
	local scope="$1" kind="$2" cfg="$3" keys_expr="$4" detail="${5:-}"
	local item
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		row "$scope" "$kind" "$item" "$detail" "$cfg"
	done < <(json_keys "$cfg" "$keys_expr")
}

# Collect JSON keys and emit rows with detail from a jq expression.
# $k is bound to the current key in DETAIL_JQ_EXPR.
# Usage: collect_json_rows_jq SCOPE KIND CONFIG_FILE JQ_KEYS_EXPR DETAIL_JQ_EXPR
collect_json_rows_jq() {
	local scope="$1" kind="$2" cfg="$3" keys_expr="$4" detail_expr="$5"
	local item detail
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		detail="$(jq -r --arg k "$item" "$detail_expr" "$cfg" 2>/dev/null || echo "n/a")"
		row "$scope" "$kind" "$item" "$detail" "$cfg"
	done < <(json_keys "$cfg" "$keys_expr")
}

# Infer MCP server type: explicit type field, else "http" if url present, else "local".
# Caller must ensure jq is available (need_cmd jq).
mcp_type_for() {
	local file="$1"
	local key="$2"
	jq -r --arg k "$key" '.mcpServers[$k].type // (if .mcpServers[$k].url then "http" else "local" end)' "$file" 2>/dev/null || echo "local"
}

# Deduplicate TSV rows by the first four columns.
dedupe_rows() {
	awk -F'\t' '!seen[$1 FS $2 FS $3 FS $4]++'
}

# List hook rows for a given scope, marking known-but-unconfigured hooks.
list_hook_rows_with_unconfigured() {
	local scope="$1"
	local source_file="$2"
	local docs_url="$3"
	shift 3

	local configured=("$@")
	declare -A seen=()

	local hook
	for hook in "${configured[@]}"; do
		[[ -n "$hook" ]] || continue
		row "$scope" "hook" "$hook" "configured" "$source_file"
		seen["$hook"]=1
	done

	local known_hooks=()
	if [[ "$scope" == "claude" ]]; then
		known_hooks=(
			"SessionStart"
			"UserPromptSubmit"
			"PreToolUse"
			"PermissionRequest"
			"PostToolUse"
			"PostToolUseFailure"
			"Notification"
			"SubagentStart"
			"SubagentStop"
			"Stop"
			"TeammateIdle"
			"TaskCompleted"
			"InstructionsLoaded"
			"ConfigChange"
			"WorktreeCreate"
			"WorktreeRemove"
			"PreCompact"
			"SessionEnd"
		)
	elif [[ "$scope" == "gemini" ]]; then
		known_hooks=(
			"BeforeTool"
			"AfterTool"
			"BeforeAgent"
			"AfterAgent"
			"BeforeModel"
			"BeforeToolSelection"
			"AfterModel"
			"SessionStart"
			"SessionEnd"
			"Notification"
			"PreCompress"
		)
	fi

	for hook in "${known_hooks[@]}"; do
		if [[ -z "${seen[$hook]:-}" ]]; then
			row "$scope" "hook" "$hook" "available (not configured)" "$docs_url"
		fi
	done
}
