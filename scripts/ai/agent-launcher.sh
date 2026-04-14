#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/fzf-theme.sh
source "${SCRIPT_DIR}/../lib/fzf-theme.sh"
# shellcheck source=scripts/ai/_agent-registry.sh
source "${SCRIPT_DIR}/_agent-registry.sh"

if ! command -v fzf >/dev/null 2>&1; then
	print_error "fzf is required"
	exit 1
fi

pick() {
	local header="$1"
	shift
	printf '%s\n' "$@" | fzf --height=50% --reverse --header="$header"
}

pick_lines() {
	local header="$1"
	fzf --height=50% --reverse --header="$header"
}

usage() {
	echo "Usage: ai-agent-launcher [-s|--simple]"
	echo "  default: sectioned mode (provider -> profile/mode -> suffix)"
	echo "  -s, --simple: flat prefix picker mode"
}

# resolve_workflow_prompt is provided by _agent-registry.sh

workflow_label() {
	case "$1" in
	cm)
		echo "commit split (cm) — Splits working tree into logical commits with validated, minimal staging."
		;;
	rf)
		echo "refactor maintainability (rf) — Improves structure and clarity without changing behavior, APIs, or workflows."
		;;
	fx)
		echo "bugfix root cause (fx) — Reproduces bugs, proves root cause, fixes minimally, validates regressions afterward."
		;;
	sa)
		echo "security audit (sa) — Finds evidence-backed security weaknesses across code, configs, dependencies, infrastructure surfaces."
		;;
	du)
		echo "dependency upgrade (du) — Upgrades dependencies safely, handles breaking changes, validates compatibility, reports blockers."
		;;
	bp)
		echo "build performance (bp) — Measures bottlenecks, applies low-risk optimizations, compares before-and-after performance evidence clearly."
		;;
	md)
		echo "markdown sync (md) — Synchronizes documentation with repository reality, removing drift, ambiguity, stale instructions."
		;;
	*)
		return 1
		;;
	esac
}

workflow_display_lines() {
	echo "none"
	local suffix
	for suffix in "${WORKFLOW_SUFFIXES[@]}"; do
		workflow_label "$suffix"
	done
}

workflow_suffix_from_selection() {
	local selection="$1"
	if [[ "$selection" == "none" ]]; then
		echo "none"
		return 0
	fi

	local suffix
	for suffix in "${WORKFLOW_SUFFIXES[@]}"; do
		if [[ "$selection" == "$(workflow_label "$suffix")" ]]; then
			echo "$suffix"
			return 0
		fi
	done

	return 1
}

choose_workflow_suffix() {
	local base_alias="$1"
	local selection suffix

	if ! is_supported_base_alias "$base_alias"; then
		echo "none"
		return 0
	fi

	selection="$(workflow_display_lines | pick_lines "Select Workflow Suffix")"
	if [[ -z "${selection:-}" ]]; then
		return 1
	fi

	suffix="$(workflow_suffix_from_selection "$selection")" || return 1

	echo "$suffix"
}

# Execute a registered agent by looking up its config in the shared AGENT_REGISTRY.
execute_agent() {
	local agent_alias="$1"
	local workflow_suffix="$2"
	local prompt=""

	if [[ "$workflow_suffix" != "none" ]]; then
		prompt="$(resolve_workflow_prompt "$workflow_suffix")"
	fi

	local entry="${AGENT_REGISTRY[$agent_alias]:-}"
	if [[ -z "$entry" ]]; then
		print_error "Unsupported alias: $agent_alias"
		exit 1
	fi

	local env_marker="${entry%%|*}"
	local command_prefix="${entry#*|}"

	# Resolve env vars
	local resolved_env=""
	case "$env_marker" in
	"-") ;;
	"ZAI") resolved_env="$(zai_claude_env | tr '\n' ' ')" ;;
	*) resolved_env="$env_marker" ;;
	esac

	# Determine how to pass the prompt (OpenCode uses --prompt flag)
	local prompt_flag=""
	if [[ "$command_prefix" == opencode* ]]; then
		prompt_flag="--prompt"
	fi

	# Execute
	if [[ -n "$resolved_env" ]]; then
		if [[ -z "$prompt" ]]; then
			# shellcheck disable=SC2086
			exec env $resolved_env $command_prefix
		else
			if [[ -n "$prompt_flag" ]]; then
				# shellcheck disable=SC2086
				exec env $resolved_env $command_prefix $prompt_flag "$prompt"
			else
				# shellcheck disable=SC2086
				exec env $resolved_env $command_prefix "$prompt"
			fi
		fi
	else
		if [[ -z "$prompt" ]]; then
			# shellcheck disable=SC2086
			exec $command_prefix
		else
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

main() {
	local simple_mode=false
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

	local agent_alias=""
	local workflow_suffix=""

	if [[ "$simple_mode" == true ]]; then
		agent_alias="$(run_simple_mode)" || exit 0
	else
		agent_alias="$(run_sectioned_mode)" || exit 0
	fi

	workflow_suffix="$(choose_workflow_suffix "$agent_alias")" || exit 0

	execute_agent "$agent_alias" "$workflow_suffix"
}

if [[ "${AI_AGENT_LAUNCHER_SOURCE_ONLY:-0}" != "1" ]]; then
	main "$@"
fi
