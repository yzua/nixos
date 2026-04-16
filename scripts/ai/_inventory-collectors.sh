#!/usr/bin/env bash
# _inventory-collectors.sh - Per-tool data collection functions for agent inventory.
# Source this file after sourcing _inventory-helpers.sh.

# List skills from a single base directory.
list_skill_dirs() {
	local base="$1"
	local scope="$2"
	if [[ ! -d "$base" ]]; then
		return 0
	fi

	shopt -s nullglob
	local d
	for d in "$base"/*; do
		[[ -d "$d" ]] || continue
		local skill_file="$d/SKILL.md"
		if [[ -f "$skill_file" ]]; then
			row "$scope" "skill" "$(basename "$d")" "$(basename "$base")" "$skill_file"
		else
			row "$scope" "skill" "$(basename "$d")" "$(basename "$base")" "$d"
		fi
	done
	shopt -u nullglob
}

# List skills from multiple base directories, deduplicating by skill name.
list_skill_dirs_merged() {
	local scope="$1"
	shift

	declare -A skill_sources=()
	declare -A skill_source_path=()

	local base d skill
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for d in "$base"/*; do
			[[ -d "$d" ]] || continue
			skill="$(basename "$d")"
			if [[ -n "${skill_sources[$skill]:-}" ]]; then
				skill_sources[$skill]="${skill_sources[$skill]}, $(basename "$base")"
			else
				skill_sources[$skill]="$(basename "$base")"
				if [[ -f "$d/SKILL.md" ]]; then
					skill_source_path[$skill]="$d/SKILL.md"
				else
					skill_source_path[$skill]="$d"
				fi
			fi
		done
		shopt -u nullglob
	done

	for skill in "${!skill_sources[@]}"; do
		row "$scope" "skill" "$skill" "${skill_sources[$skill]}" "${skill_source_path[$skill]}"
	done
}

# List skill slash commands from multiple base directories, deduplicating.
list_skill_commands_merged() {
	local scope="$1"
	shift

	declare -A cmd_source_path=()
	local base d skill
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for d in "$base"/*; do
			[[ -d "$d" ]] || continue
			skill="$(basename "$d")"
			if [[ -z "${cmd_source_path[$skill]:-}" ]]; then
				if [[ -f "$d/SKILL.md" ]]; then
					cmd_source_path[$skill]="$d/SKILL.md"
				else
					cmd_source_path[$skill]="$d"
				fi
			fi
		done
		shopt -u nullglob
	done

	for skill in "${!cmd_source_path[@]}"; do
		row "$scope" "command" "/$skill" "skill slash command" "${cmd_source_path[$skill]}"
	done
}

# List command files from a directory.
list_command_files() {
	local base="$1"
	local scope="$2"
	if [[ ! -d "$base" ]]; then
		return 0
	fi

	shopt -s nullglob
	local f
	for f in "$base"/*; do
		[[ -f "$f" ]] || continue
		row "$scope" "command" "$(basename "$f")" "file" "$f"
	done
	shopt -u nullglob
}

# List agent definition files from multiple directories, deduplicating by name.
list_agent_files_merged() {
	local scope="$1"
	shift

	declare -A seen=()
	local base f name
	for base in "$@"; do
		[[ -d "$base" ]] || continue
		shopt -s nullglob
		for f in "$base"/*.md; do
			[[ -f "$f" ]] || continue
			name="$(basename "$f" .md)"
			if [[ -z "${seen[$name]:-}" ]]; then
				row "$scope" "agent" "$name" "file agent definition" "$f"
				seen[$name]=1
			fi
		done
		shopt -u nullglob
	done
}

# Collect OpenCode inventory rows.
collect_opencode() {
	shopt -s nullglob
	local profiles=("$HOME"/.config/opencode*/opencode.json)
	local agent_dirs=("$HOME"/.config/opencode*/agents)
	local skill_dirs=("$HOME"/.config/opencode*/skills)
	shopt -u nullglob

	local cfg profile_dir profile_name model small_model
	for cfg in "${profiles[@]}"; do
		profile_dir="$(dirname "$cfg")"
		profile_name="$(basename "$profile_dir")"

		model="$(jq -r '.model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"
		small_model="$(jq -r '.small_model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"

		row "opencode" "profile" "$profile_name" "model=$model" "$cfg"
		row "opencode" "small_model" "$profile_name" "$small_model" "$cfg"

		while IFS= read -r cmd; do
			[[ -n "$cmd" ]] || continue
			local desc
			desc="$(jq -r --arg k "$cmd" '.command[$k].description // "no description"' "$cfg" 2>/dev/null || echo "no description")"
			row "opencode" "command" "$cmd" "$desc" "$cfg"
		done < <(json_keys "$cfg" '.command // {} | keys[]')

		while IFS= read -r plugin; do
			[[ -n "$plugin" ]] || continue
			row "opencode" "plugin" "$plugin" "enabled" "$cfg"
		done < <(json_keys "$cfg" '.plugin // [] | .[]')

		while IFS= read -r mcp; do
			[[ -n "$mcp" ]] || continue
			local mcp_type
			mcp_type="$(jq -r --arg k "$mcp" '.mcp[$k].type // "local"' "$cfg" 2>/dev/null || echo "local")"
			row "opencode" "mcp" "$mcp" "$mcp_type" "$cfg"
		done < <(json_keys "$cfg" '.mcp // {} | keys[]')

		while IFS= read -r provider; do
			[[ -n "$provider" ]] || continue
			row "opencode" "provider" "$provider" "configured" "$cfg"
		done < <(json_keys "$cfg" '.provider // {} | keys[]')
	done

	list_agent_files_merged "opencode" "${agent_dirs[@]}"
	list_skill_dirs_merged "opencode" "${skill_dirs[@]}" "$HOME/.agents/skills" "$PWD/.agents/skills"
	list_skill_commands_merged "opencode" "${skill_dirs[@]}" "$HOME/.agents/skills" "$PWD/.agents/skills"
}

# Collect Claude inventory rows.
collect_claude() {
	local cfg="$HOME/.claude/settings.json"
	if [[ -f "$cfg" ]]; then
		row "claude" "model" "default" "$(jq -r '.model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")" "$cfg"

		mapfile -t claude_configured_hooks < <(json_keys "$cfg" '.hooks // {} | keys[]')
		list_hook_rows_with_unconfigured "claude" "$cfg" "https://code.claude.com/docs/en/hooks" "${claude_configured_hooks[@]}"

		while IFS= read -r plugin; do
			[[ -n "$plugin" ]] || continue
			row "claude" "plugin" "$plugin" "enabled" "$cfg"
		done < <(json_keys "$cfg" '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key')
	fi

	local mcp_cfg="$HOME/.mcp.json"
	if [[ -f "$mcp_cfg" ]]; then
		while IFS= read -r server; do
			[[ -n "$server" ]] || continue
			local mcp_type
			mcp_type="$(mcp_type_for "$mcp_cfg" "$server")"
			row "claude" "mcp" "$server" "$mcp_type" "$mcp_cfg"
		done < <(json_keys "$mcp_cfg" '.mcpServers // {} | keys[]')
	fi

	local agents_dir="$HOME/.claude/agents"
	if [[ -d "$agents_dir" ]]; then
		shopt -s nullglob
		local a
		for a in "$agents_dir"/*.md; do
			[[ -f "$a" ]] || continue
			local name
			name="$(awk -F': ' '/^name:/ {print $2; exit}' "$a" 2>/dev/null || true)"
			if [[ -z "$name" ]]; then
				name="$(basename "$a" .md)"
			fi
			row "claude" "agent" "$name" "local agent definition" "$a"
		done
		shopt -u nullglob
	fi

	list_skill_dirs_merged "claude" "$HOME/.claude/skills" "$HOME/.agents/skills"
	list_command_files "$HOME/.claude/commands" "claude"
}

# Collect Codex inventory rows.
collect_codex() {
	need_cmd python3
	local cfg="$HOME/.codex/config.toml"
	local agents_dir="$HOME/.codex/agents"
	if [[ -f "$cfg" ]]; then
		python3 - "$cfg" <<'PY'
import pathlib
import sys
import tomllib

cfg = pathlib.Path(sys.argv[1])
data = tomllib.loads(cfg.read_text(encoding="utf-8"))

def emit(kind: str, name: str, detail: str):
    print(f"codex\t{kind}\t{name}\t{detail}\t{cfg}")

emit("model", "default", str(data.get("model", "n/a")))
emit("reasoning_effort", "default", str(data.get("model_reasoning_effort", "n/a")))

for profile in sorted((data.get("profiles") or {}).keys()):
    emit("profile", profile, "configured")

for server, value in sorted((data.get("mcp_servers") or {}).items()):
    if isinstance(value, dict):
        enabled = value.get("enabled", True)
        emit("mcp", server, f"enabled={enabled}")

for agent in sorted((data.get("agents") or {}).keys()):
    if agent == "max_threads":
        continue
    emit("agent", agent, "configured")
PY
	fi

	list_skill_dirs_merged "codex" "$HOME/.codex/skills" "$HOME/.codex/skills/.system" "$HOME/.agents/skills" "$PWD/.agents/skills"
	list_command_files "$HOME/.codex/commands" "codex"
	if [[ -d "$agents_dir" ]]; then
		python3 - "$agents_dir" <<'PY'
import pathlib
import sys
import tomllib

agents_dir = pathlib.Path(sys.argv[1])
for agent_file in sorted(agents_dir.glob("*.toml")):
    try:
        data = tomllib.loads(agent_file.read_text(encoding="utf-8"))
    except Exception:
        continue
    name = str(data.get("name", agent_file.stem))
    desc = str(data.get("description", "custom agent"))
    print(f"codex\tagent\t{name}\t{desc}\t{agent_file}")
PY
	fi
}

# Collect Gemini inventory rows.
collect_gemini() {
	local cfg="$HOME/.gemini/settings.json"
	if [[ -f "$cfg" ]]; then
		while IFS= read -r alias; do
			[[ -n "$alias" ]] || continue
			local model
			model="$(jq -r --arg k "$alias" '.modelConfigs.customAliases[$k].modelConfig.model // "n/a"' "$cfg" 2>/dev/null || echo "n/a")"
			row "gemini" "model_alias" "$alias" "$model" "$cfg"
		done < <(json_keys "$cfg" '.modelConfigs.customAliases // {} | keys[]')

		mapfile -t gemini_configured_hooks < <(json_keys "$cfg" '.hooks // {} | keys[]')
		list_hook_rows_with_unconfigured "gemini" "$cfg" "https://geminicli.com/docs/hooks/reference/" "${gemini_configured_hooks[@]}"

		while IFS= read -r mcp; do
			[[ -n "$mcp" ]] || continue
			local mcp_type
			mcp_type="$(mcp_type_for "$cfg" "$mcp")"
			row "gemini" "mcp" "$mcp" "$mcp_type" "$cfg"
		done < <(json_keys "$cfg" '.mcpServers // {} | keys[]')
	fi

	list_skill_dirs "$HOME/.gemini/skills" "gemini"
	list_command_files "$HOME/.gemini/commands" "gemini"
}

# Dispatch to the correct collector(s) for a tool name.
collect_rows_for_tool() {
	local tool="$1"
	case "$tool" in
	opencode)
		collect_opencode
		;;
	claude)
		collect_claude
		;;
	codex)
		collect_codex
		;;
	gemini)
		collect_gemini
		;;
	all)
		collect_opencode
		collect_claude
		collect_codex
		collect_gemini
		;;
	*)
		print_error "Unknown tool: $tool"
		exit 1
		;;
	esac
}
