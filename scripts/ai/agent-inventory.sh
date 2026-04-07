#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

# Ensure fzf inherits Home Manager theme when launched outside interactive shells.
if [[ -z "${FZF_DEFAULT_OPTS:-}" ]] && [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
	# shellcheck disable=SC1091
	source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
	export FZF_DEFAULT_OPTS="--color=fg:#ebdbb2,bg:#32302f,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#8ec07c,prompt:#83a598,pointer:#fe8019,marker:#b8bb26,spinner:#d3869b,header:#928374,border:#504945,gutter:#282828"
fi

if ! command -v fzf >/dev/null 2>&1; then
	print_error "fzf is required"
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	print_error "jq is required"
	exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
	print_error "python3 is required"
	exit 1
fi

usage() {
	cat <<'EOF'
Usage: ai-agent-inventory [--tool TOOL] [--section SECTION]

Dynamic AI tool inventory browser.

TOOL values:
  opencode | claude | codex | gemini | all

SECTION values:
  all | profile | model | small_model | command | plugin | mcp | provider |
  agent | category | skill | hook | model_alias | reasoning_effort

Without --tool/--section, fzf pickers are shown.
EOF
}

row() {
	local tool="$1"
	local kind="$2"
	local name="$3"
	local detail="$4"
	local source="$5"
	printf '%s\t%s\t%s\t%s\t%s\n' "$tool" "$kind" "$name" "$detail" "$source"
}

sanitize() {
	sed -E \
		-e 's/(gho_[A-Za-z0-9_]+)/[REDACTED]/g' \
		-e 's/(sk-[A-Za-z0-9_-]+)/[REDACTED]/g' \
		-e 's/(Bearer )[A-Za-z0-9._-]+/\1[REDACTED]/g'
}

json_keys() {
	local file="$1"
	local expr="$2"
	jq -r "$expr" "$file" 2>/dev/null || true
}

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
			mcp_type="$(jq -r --arg k "$server" '.mcpServers[$k].type // (if .mcpServers[$k].url then "http" else "local" end)' "$mcp_cfg" 2>/dev/null || echo "local")"
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

collect_codex() {
	local cfg="$HOME/.codex/config.toml"
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
}

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
			mcp_type="$(jq -r --arg k "$mcp" '.mcpServers[$k].type // (if .mcpServers[$k].url then "http" else "local" end)' "$cfg" 2>/dev/null || echo "local")"
			row "gemini" "mcp" "$mcp" "$mcp_type" "$cfg"
		done < <(json_keys "$cfg" '.mcpServers // {} | keys[]')
	fi

	list_skill_dirs "$HOME/.gemini/skills" "gemini"
	list_command_files "$HOME/.gemini/commands" "gemini"
}

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

dedupe_rows() {
	awk -F'\t' '!seen[$1 FS $2 FS $3 FS $4]++'
}

pick_tool() {
	printf '%s\n' "all" "opencode" "claude" "codex" "gemini" |
		fzf --height=40% --reverse --header="Select Tool Family"
}

pick_section() {
	local rows_file="$1"
	{
		printf 'all\tALL sections\n'
		awk -F'\t' '{count[$2]++} END {for (k in count) printf "%s\t%d entries\n", k, count[k]}' "$rows_file" | sort
	} |
		fzf --height=45% --reverse --header="Select Section" --with-nth=1,2 --delimiter=$'\t' |
		cut -f1
}

tool=""
section=""
section_locked="false"
while [[ $# -gt 0 ]]; do
	case "$1" in
	--tool)
		shift
		if [[ $# -eq 0 ]]; then
			print_error "--tool requires a value"
			exit 1
		fi
		tool="$1"
		;;
	--section)
		shift
		if [[ $# -eq 0 ]]; then
			print_error "--section requires a value"
			exit 1
		fi
		section="$1"
		section_locked="true"
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		print_error "Unknown argument: $1"
		usage >&2
		exit 1
		;;
	esac
	shift
done

if [[ -z "$tool" ]]; then
	tool="$(pick_tool)"
	if [[ -z "${tool:-}" ]]; then
		exit 0
	fi
fi

tmp_rows="$(mktemp)"
tmp_filtered="$(mktemp)"
trap 'rm -f "$tmp_rows" "$tmp_filtered"' EXIT

collect_rows_for_tool "$tool" | dedupe_rows | sort -u >"$tmp_rows"

if [[ ! -s "$tmp_rows" ]]; then
	print_error "No inventory data found for tool: $tool"
	exit 1
fi

while true; do
	if [[ -z "$section" ]]; then
		section="$(pick_section "$tmp_rows")"
		if [[ -z "${section:-}" ]]; then
			exit 0
		fi
	fi

	if [[ "$section" == "all" ]]; then
		cp "$tmp_rows" "$tmp_filtered"
	else
		awk -F'\t' -v want="$section" '$2 == want' "$tmp_rows" >"$tmp_filtered"
	fi

	if [[ ! -s "$tmp_filtered" ]]; then
		print_error "No entries found for tool=$tool section=$section"
		if [[ "$section_locked" == "true" ]]; then
			exit 1
		fi
		section=""
		continue
	fi

	selected="$({
		fzf --height=90% \
			--reverse \
			--header="${tool}/${section}: filter entries (ENTER opens source file, ESC back)" \
			--delimiter=$'\t' \
			--with-nth=1,2,3,4 \
			--preview 'printf "Tool: %s\nKind: %s\nName: %s\nDetail: %s\nSource: %s\n" {1} {2} {3} {4} {5} | sed -E "s/(gho_[A-Za-z0-9_]+)/[REDACTED]/g; s/(sk-[A-Za-z0-9_-]+)/[REDACTED]/g; s/(Bearer )[A-Za-z0-9._-]+/\1[REDACTED]/g"' \
			<"$tmp_filtered"
	} || true)"

	if [[ -z "${selected:-}" ]]; then
		if [[ "$section_locked" == "true" ]]; then
			exit 0
		fi
		section=""
		continue
	fi

	sel_source="$(printf '%s\n' "$selected" | awk -F'\t' '{print $5}')"

	if [[ -n "${sel_source:-}" ]] && [[ -e "$sel_source" ]]; then
		editor_cmd="${EDITOR:-${VISUAL:-nvim}}"
		if command -v "$editor_cmd" >/dev/null 2>&1; then
			"$editor_cmd" "$sel_source"
			echo "Opened: $sel_source"
		elif command -v nvim >/dev/null 2>&1; then
			nvim "$sel_source"
			echo "Opened: $sel_source"
		elif command -v less >/dev/null 2>&1; then
			less "$sel_source"
			echo "Viewed: $sel_source"
		else
			printf '%s\n' "$selected" | sanitize
		fi
	else
		printf '%s\n' "$selected" | sanitize
	fi

	if [[ "$section_locked" == "true" ]]; then
		exit 0
	fi

	section=""
done
