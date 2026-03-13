#!/usr/bin/env bash
set -euo pipefail

# Ensure fzf inherits Home Manager theme when launched outside interactive shells.
if [[ -z "${FZF_DEFAULT_OPTS:-}" ]] && [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
	# shellcheck disable=SC1091
	source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
	export FZF_DEFAULT_OPTS="--color=fg:#ebdbb2,bg:#32302f,hl:#fabd2f,fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f,info:#8ec07c,prompt:#83a598,pointer:#fe8019,marker:#b8bb26,spinner:#d3869b,header:#928374,border:#504945,gutter:#282828"
fi

COMMIT_SPLIT_PROMPT="${COMMIT_SPLIT_PROMPT:-}"
REFACTOR_MAINTAINABILITY_PROMPT="${REFACTOR_MAINTAINABILITY_PROMPT:-}"
SECURITY_AUDIT_PROMPT="${SECURITY_AUDIT_PROMPT:-}"
BUILD_PERFORMANCE_PROMPT="${BUILD_PERFORMANCE_PROMPT:-}"
MARKDOWN_SYNC_PROMPT="${MARKDOWN_SYNC_PROMPT:-}"

if ! command -v fzf >/dev/null 2>&1; then
	echo "Error: fzf is required" >&2
	exit 1
fi

pick() {
	local header="$1"
	shift
	printf '%s\n' "$@" | fzf --height=50% --reverse --header="$header"
}

usage() {
	echo "Usage: ai-agent-launcher [-s|--simple]"
	echo "  default: sectioned mode (provider -> profile/mode -> suffix)"
	echo "  -s, --simple: flat prefix picker mode"
}

supports_workflow_suffix() {
	case "$1" in
	cl | clu | clglm | ocl | hcl | cx | cxu | lcx | mcx | hcx | xcx | oc | ocglm | ocgem | ocgpt | locgpt | mocgpt | hocgpt | xocgpt | ocs | oczen)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

resolve_workflow_prompt() {
	case "$1" in
	cm)
		echo "$COMMIT_SPLIT_PROMPT"
		;;
	rf)
		echo "$REFACTOR_MAINTAINABILITY_PROMPT"
		;;
	sa)
		echo "$SECURITY_AUDIT_PROMPT"
		;;
	bp)
		echo "$BUILD_PERFORMANCE_PROMPT"
		;;
	md)
		echo "$MARKDOWN_SYNC_PROMPT"
		;;
	*)
		return 1
		;;
	esac
}

choose_workflow_suffix() {
	local base_alias="$1"
	local suffix

	if ! supports_workflow_suffix "$base_alias"; then
		echo "none"
		return 0
	fi

	suffix="$(pick "Select Workflow Suffix" none cm rf sa bp md)"
	if [[ -z "${suffix:-}" ]]; then
		return 1
	fi

	echo "$suffix"
}

execute_claude_glm() {
	local prompt="${1:-}"
	local key_file key

	key_file="${ZAI_API_KEY_FILE:-/run/secrets/zai_api_key}"
	if [[ ! -f "$key_file" ]]; then
		echo "Error: $key_file not found. Run 'just nixos' to decrypt secrets." >&2
		exit 1
	fi

	key="$(cat "$key_file")"
	if [[ -z "$prompt" ]]; then
		exec env \
			ANTHROPIC_AUTH_TOKEN="$key" \
			ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
			API_TIMEOUT_MS="3000000" \
			ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
			ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5" \
			ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5" \
			claude --dangerously-skip-permissions
	else
		exec env \
			ANTHROPIC_AUTH_TOKEN="$key" \
			ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
			API_TIMEOUT_MS="3000000" \
			ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
			ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5" \
			ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5" \
			claude --dangerously-skip-permissions "$prompt"
	fi
}

execute_agent() {
	local agent_alias="$1"
	local workflow_suffix="$2"
	local prompt=""

	if [[ "$workflow_suffix" != "none" ]]; then
		prompt="$(resolve_workflow_prompt "$workflow_suffix")"
	fi

	case "$agent_alias" in
	cl | clu)
		if [[ -z "$prompt" ]]; then
			exec claude --dangerously-skip-permissions
		else
			exec claude --dangerously-skip-permissions "$prompt"
		fi
		;;
	ocl)
		if [[ -z "$prompt" ]]; then
			exec claude --dangerously-skip-permissions --model opus
		else
			exec claude --dangerously-skip-permissions --model opus "$prompt"
		fi
		;;
	hcl)
		if [[ -z "$prompt" ]]; then
			exec claude --dangerously-skip-permissions --model haiku
		else
			exec claude --dangerously-skip-permissions --model haiku "$prompt"
		fi
		;;
	clglm)
		execute_claude_glm "$prompt"
		;;
	gem)
		exec gemini --yolo
		;;
	cx | cxu)
		if [[ -z "$prompt" ]]; then
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox
		else
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox "$prompt"
		fi
		;;
	lcx)
		if [[ -z "$prompt" ]]; then
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="low"'
		else
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="low"' "$prompt"
		fi
		;;
	mcx)
		if [[ -z "$prompt" ]]; then
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="medium"'
		else
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="medium"' "$prompt"
		fi
		;;
	hcx)
		if [[ -z "$prompt" ]]; then
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="high"'
		else
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="high"' "$prompt"
		fi
		;;
	xcx)
		if [[ -z "$prompt" ]]; then
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="xhigh"'
		else
			exec codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="xhigh"' "$prompt"
		fi
		;;
	oc)
		if [[ -z "$prompt" ]]; then
			exec opencode
		else
			exec opencode --prompt "$prompt"
		fi
		;;
	ocglm)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-glm" opencode
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-glm" opencode --prompt "$prompt"
		fi
		;;
	ocgem)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gemini" opencode
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gemini" opencode --prompt "$prompt"
		fi
		;;
	ocgpt)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --prompt "$prompt"
		fi
		;;
	locgpt)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex-spark
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex-spark --prompt "$prompt"
		fi
		;;
	mocgpt)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.3-codex --prompt "$prompt"
		fi
		;;
	hocgpt)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.4
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.4 --prompt "$prompt"
		fi
		;;
	xocgpt)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.1-codex-max
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-gpt" opencode --model openai/gpt-5.1-codex-max --prompt "$prompt"
		fi
		;;
	ocs)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-sonnet" opencode
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-sonnet" opencode --prompt "$prompt"
		fi
		;;
	oczen)
		if [[ -z "$prompt" ]]; then
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-zen" opencode
		else
			exec env OPENCODE_CONFIG_DIR="$HOME/.config/opencode-zen" opencode --prompt "$prompt"
		fi
		;;
	*)
		echo "Unsupported alias: $agent_alias" >&2
		exit 1
		;;
	esac
}

pick_codex_effort_alias() {
	local effort
	effort="$(pick "Codex Reasoning Effort" default low medium high xhigh)"
	case "$effort" in
	default) echo "cx" ;;
	low) echo "lcx" ;;
	medium) echo "mcx" ;;
	high) echo "hcx" ;;
	xhigh) echo "xcx" ;;
	"") return 1 ;;
	esac
}

pick_ocgpt_effort_alias() {
	local effort
	effort="$(pick "OpenCode GPT Reasoning Effort" default low medium high xhigh)"
	case "$effort" in
	default) echo "ocgpt" ;;
	low) echo "locgpt" ;;
	medium) echo "mocgpt" ;;
	high) echo "hocgpt" ;;
	xhigh) echo "xocgpt" ;;
	"") return 1 ;;
	esac
}

run_simple_mode() {
	local agent_alias claude_mode

	agent_alias="$(pick "Simple Mode: Select Agent Prefix" \
		cl ocl hcl clglm \
		oc ocglm ocgem ocgpt locgpt mocgpt hocgpt xocgpt ocs oczen \
		cx lcx mcx hcx xcx cxu \
		gem)"
	if [[ -z "${agent_alias:-}" ]]; then
		return 1
	fi

	if [[ "$agent_alias" == "cl" ]]; then
		claude_mode="$(pick "Claude Model" default opus haiku)"
		case "$claude_mode" in
		default) agent_alias="cl" ;;
		opus) agent_alias="ocl" ;;
		haiku) agent_alias="hcl" ;;
		"") return 1 ;;
		esac
	fi

	case "$agent_alias" in
	cx | lcx | mcx | hcx | xcx)
		agent_alias="$(pick_codex_effort_alias)" || return 1
		;;
	esac

	case "$agent_alias" in
	ocgpt | locgpt | mocgpt | hocgpt | xocgpt)
		agent_alias="$(pick_ocgpt_effort_alias)" || return 1
		;;
	esac

	echo "$agent_alias"
}

run_sectioned_mode() {
	local provider_choice profile_choice mode_choice agent_alias

	provider_choice="$(pick "Select Provider" "OpenCode" "Claude Code" "Codex" "Gemini")"
	if [[ -z "${provider_choice:-}" ]]; then
		return 1
	fi

	case "$provider_choice" in
	"OpenCode")
		profile_choice="$(pick "OpenCode Profile" default glm gemini gpt sonnet zen)"
		case "$profile_choice" in
		default) agent_alias="oc" ;;
		glm) agent_alias="ocglm" ;;
		gemini) agent_alias="ocgem" ;;
		gpt) agent_alias="$(pick_ocgpt_effort_alias)" || return 1 ;;
		sonnet) agent_alias="ocs" ;;
		zen) agent_alias="oczen" ;;
		"") return 1 ;;
		esac
		;;
	"Claude Code")
		mode_choice="$(pick "Claude Mode" default opus haiku glm)"
		case "$mode_choice" in
		default) agent_alias="cl" ;;
		opus) agent_alias="ocl" ;;
		haiku) agent_alias="hcl" ;;
		glm) agent_alias="clglm" ;;
		"") return 1 ;;
		esac
		;;
	"Codex")
		agent_alias="$(pick_codex_effort_alias)" || return 1
		;;
	"Gemini")
		agent_alias="gem"
		;;
	esac

	echo "$agent_alias"
}

simple_mode=false
while [[ $# -gt 0 ]]; do
	case "$1" in
	-s | --simple)
		simple_mode=true
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown argument: $1" >&2
		usage >&2
		exit 1
		;;
	esac
	shift
done

agent_alias=""
workflow_suffix=""

if [[ "$simple_mode" == true ]]; then
	agent_alias="$(run_simple_mode)" || exit 0
else
	agent_alias="$(run_sectioned_mode)" || exit 0
fi

workflow_suffix="$(choose_workflow_suffix "$agent_alias")" || exit 0

execute_agent "$agent_alias" "$workflow_suffix"
