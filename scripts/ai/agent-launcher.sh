#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/fzf-theme.sh
source "${SCRIPT_DIR}/../lib/fzf-theme.sh"

COMMIT_SPLIT_PROMPT="${COMMIT_SPLIT_PROMPT:-}"
REFACTOR_MAINTAINABILITY_PROMPT="${REFACTOR_MAINTAINABILITY_PROMPT:-}"
SECURITY_AUDIT_PROMPT="${SECURITY_AUDIT_PROMPT:-}"
BUILD_PERFORMANCE_PROMPT="${BUILD_PERFORMANCE_PROMPT:-}"
MARKDOWN_SYNC_PROMPT="${MARKDOWN_SYNC_PROMPT:-}"

if ! command -v fzf >/dev/null 2>&1; then
	print_error "fzf is required"
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

# --- Agent registry ---
#
# Each entry:  "alias|env|command_prefix|extra_args..."
#   env:  environment variable assignments (space-separated KEY=VAL pairs), or "-"
#   command_prefix: the base command (everything before --prompt)
#   extra_args: any additional flags after the command but before the prompt
#
# Aliases that need custom logic (clglm, cxu, gem) use case-branch fallbacks.

declare -A AGENT_REGISTRY

# Claude Code
AGENT_REGISTRY[cl]="-|claude --dangerously-skip-permissions"
AGENT_REGISTRY[clu]="-|claude --dangerously-skip-permissions"
AGENT_REGISTRY[ocl]="-|claude --dangerously-skip-permissions --model opus"
AGENT_REGISTRY[hcl]="-|claude --dangerously-skip-permissions --model haiku"

# Codex
AGENT_REGISTRY[cx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox"
AGENT_REGISTRY[cxu]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox"
AGENT_REGISTRY[lcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"low\"'"
AGENT_REGISTRY[mcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"medium\"'"
AGENT_REGISTRY[hcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"high\"'"
AGENT_REGISTRY[xcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"xhigh\"'"

# OpenCode (default and profiles)
AGENT_REGISTRY[oc]="-|opencode"
AGENT_REGISTRY[ocglm]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-glm|opencode"
AGENT_REGISTRY[ocgem]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gemini|opencode"
AGENT_REGISTRY[ocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode"
AGENT_REGISTRY[locgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode --model openai/gpt-5.4-spark"
AGENT_REGISTRY[mocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode --model openai/gpt-5.4"
AGENT_REGISTRY[xocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode --model openai/gpt-5.1-codex-max"
AGENT_REGISTRY[ocs]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-sonnet|opencode"
AGENT_REGISTRY[oczen]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-zen|opencode"

supports_workflow_suffix() {
	case "$1" in
	cl | clu | clglm | ocl | hcl | cx | cxu | lcx | mcx | hcx | xcx | oc | ocglm | ocgem | ocgpt | locgpt | mocgpt | xocgpt | ocs | oczen)
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

# Execute a registered agent by looking up its config in AGENT_REGISTRY.
# For agents with custom logic (clglm, cxu, gem), falls through to case branches.
execute_agent() {
	local agent_alias="$1"
	local workflow_suffix="$2"
	local prompt=""

	if [[ "$workflow_suffix" != "none" ]]; then
		prompt="$(resolve_workflow_prompt "$workflow_suffix")"
	fi

	# Special-case agents with custom env or non-standard exec logic
	case "$agent_alias" in
	clglm)
		local key_file key
		key_file="${ZAI_API_KEY_FILE:-/run/secrets/zai_api_key}"
		if [[ ! -f "$key_file" ]]; then
			print_error "$key_file not found. Run 'just nixos' to decrypt secrets."
			exit 1
		fi
		key="$(cat "$key_file")"
		if [[ -z "$prompt" ]]; then
			exec env \
				ANTHROPIC_AUTH_TOKEN="$key" \
				ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
				API_TIMEOUT_MS="3000000" \
				ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-5-turbo" \
				ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1" \
				ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1" \
				claude --dangerously-skip-permissions
		else
			exec env \
				ANTHROPIC_AUTH_TOKEN="$key" \
				ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
				API_TIMEOUT_MS="3000000" \
				ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-5-turbo" \
				ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1" \
				ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1" \
				claude --dangerously-skip-permissions "$prompt"
		fi
		;;
	gem)
		if [[ -z "$prompt" ]]; then
			exec gemini --approval-mode=yolo
		else
			exec gemini --approval-mode=yolo "$prompt"
		fi
		;;
	esac

	# Registry-based execution
	local entry="${AGENT_REGISTRY[$agent_alias]:-}"
	if [[ -z "$entry" ]]; then
		print_error "Unsupported alias: $agent_alias"
		exit 1
	fi

	local env_vars command_prefix
	env_vars="${entry%%|*}"
	command_prefix="${entry#*|}"

	# Determine how to pass the prompt (different agents use different flags)
	local prompt_flag=""
	if [[ "$command_prefix" == opencode* ]]; then
		prompt_flag="--prompt"
	fi

	if [[ "$env_vars" != "-" ]]; then
		if [[ -z "$prompt" ]]; then
			# shellcheck disable=SC2086
			exec env $env_vars $command_prefix
		else
			# shellcheck disable=SC2086
			exec env $env_vars $command_prefix $prompt_flag "$prompt"
		fi
	else
		if [[ -z "$prompt" ]]; then
			# shellcheck disable=SC2086
			exec $command_prefix
		else
			# Claude and Codex pass prompt as positional arg (no flag)
			if [[ -n "$prompt_flag" ]]; then
				# shellcheck disable=SC2086
				exec $command_prefix $prompt_flag "$prompt"
			else
				# shellcheck disable=SC2086
				exec $command_prefix "$prompt"
			fi
		fi
	fi
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
	high) echo "xocgpt" ;;
	xhigh) echo "xocgpt" ;;
	"") return 1 ;;
	esac
}

run_simple_mode() {
	local agent_alias claude_mode

	agent_alias="$(pick "Simple Mode: Select Agent Prefix" \
		cl ocl hcl clglm \
		oc ocglm ocgem ocgpt locgpt mocgpt xocgpt ocs oczen \
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
	ocgpt | locgpt | mocgpt | xocgpt)
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
		profile_choice="$(pick "OpenCode profile" default glm gemini gpt sonnet zen)"
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
		mode_choice="$(pick "Codex Mode" default yolo)"
		case "$mode_choice" in
		default) agent_alias="$(pick_codex_effort_alias)" || return 1 ;;
		yolo) agent_alias="cxu" ;;
		"") return 1 ;;
		esac
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
		print_error "Unknown argument: $1"
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
