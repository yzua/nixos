#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

usage() {
	cat <<'EOF'
Usage: iter [count] <agent-alias> [prompt...]

Examples:
  iter clglmmd
  iter 3 oc "fix the failing check"
  iter 5 gem "review this repo again"

Notes:
  - iter is headless/non-interactive. It will not open a persistent TUI.
  - Provide a prompt explicitly, or use a workflow alias like occm / clglmmd.
EOF
}

require_secret_file() {
	local path="$1"
	if [[ ! -f "${path}" ]]; then
		print_error "${path} not found. Run 'just nixos' to decrypt secrets."
		exit 1
	fi
}

zai_key_path() {
	printf '%s\n' "${ZAI_API_KEY_FILE:-/run/secrets/zai_api_key}"
}

is_supported_base_alias() {
	case "$1" in
	cl | clu | clglm | ocl | hcl | gem | cx | cxu | lcx | mcx | hcx | xcx | oc | ocglm | ocgem | ocgpt | locgpt | mocgpt | xocgpt | ocs | oczen)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

split_alias_suffix() {
	local alias_name="$1"
	local suffix
	local candidate

	for suffix in cm rf fx sa du bp md; do
		if [[ "${alias_name}" == *"${suffix}" ]]; then
			candidate="${alias_name%"${suffix}"}"
			if is_supported_base_alias "${candidate}"; then
				printf '%s|%s\n' "${candidate}" "${suffix}"
				return 0
			fi
		fi
	done

	printf '%s|\n' "${alias_name}"
}

resolve_workflow_prompt() {
	case "$1" in
	cm)
		printf '%s\n' "${COMMIT_SPLIT_PROMPT:-}"
		;;
	rf)
		printf '%s\n' "${REFACTOR_MAINTAINABILITY_PROMPT:-}"
		;;
	fx)
		printf '%s\n' "${BUGFIX_ROOT_CAUSE_PROMPT:-}"
		;;
	sa)
		printf '%s\n' "${SECURITY_AUDIT_PROMPT:-}"
		;;
	du)
		printf '%s\n' "${DEPENDENCY_UPGRADE_PROMPT:-}"
		;;
	bp)
		printf '%s\n' "${BUILD_PERFORMANCE_PROMPT:-}"
		;;
	md)
		printf '%s\n' "${MARKDOWN_SYNC_PROMPT:-}"
		;;
	*)
		printf '%s\n' ""
		;;
	esac
}

collect_prompt() {
	if [[ $# -eq 0 ]]; then
		printf '%s\n' ""
		return 0
	fi

	if [[ "$1" == "--prompt" ]]; then
		shift
	fi

	printf '%s\n' "$*"
}

run_agent_once() {
	local alias_name="$1"
	local prompt="$2"

	case "${alias_name}" in
	cl)
		claude --print "${prompt}"
		;;
	clu)
		claude --dangerously-skip-permissions --print "${prompt}"
		;;
	ocl)
		claude --model opus --print "${prompt}"
		;;
	hcl)
		claude --model haiku --print "${prompt}"
		;;
	clglm)
		local key_path
		key_path="$(zai_key_path)"
		require_secret_file "${key_path}"
		ANTHROPIC_AUTH_TOKEN="$(<"${key_path}")" \
		ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
		API_TIMEOUT_MS="3000000" \
		ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-5-turbo" \
		ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1" \
		ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1" \
			claude --dangerously-skip-permissions --print "${prompt}"
		;;
	gem)
		gemini --approval-mode=yolo --prompt "${prompt}"
		;;
	cx | cxu)
		codex exec --dangerously-bypass-approvals-and-sandbox "${prompt}"
		;;
	lcx)
		codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="low"' "${prompt}"
		;;
	mcx)
		codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="medium"' "${prompt}"
		;;
	hcx)
		codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="high"' "${prompt}"
		;;
	xcx)
		codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="xhigh"' "${prompt}"
		;;
	oc)
		opencode run "${prompt}"
		;;
	ocglm)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-glm" opencode run "${prompt}"
		;;
	ocgem)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-gemini" opencode run "${prompt}"
		;;
	ocgpt)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-gpt" opencode run "${prompt}"
		;;
	locgpt)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-gpt" opencode run --model openai/gpt-5.4-spark "${prompt}"
		;;
	mocgpt)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-gpt" opencode run --model openai/gpt-5.4 "${prompt}"
		;;
	xocgpt)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-gpt" opencode run --model openai/gpt-5.1-codex-max "${prompt}"
		;;
	ocs)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-sonnet" opencode run "${prompt}"
		;;
	oczen)
		OPENCODE_CONFIG_DIR="${HOME}/.config/opencode-zen" opencode run "${prompt}"
		;;
	*)
		print_error "Unsupported alias for iter: ${alias_name}"
		exit 1
		;;
	esac
}

if [[ $# -eq 0 ]]; then
	usage
	exit 1
fi

iteration_limit="unlimited"
if [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
	iteration_limit="$1"
	shift
fi

if [[ $# -eq 0 ]]; then
	usage
	exit 1
fi

alias_spec="$(split_alias_suffix "$1")"
agent_alias="${alias_spec%%|*}"
workflow_suffix="${alias_spec#*|}"
shift

if ! is_supported_base_alias "${agent_alias}"; then
	print_error "Unsupported alias for iter: ${agent_alias}"
	exit 1
fi

workflow_prompt="$(resolve_workflow_prompt "${workflow_suffix}")"
explicit_prompt="$(collect_prompt "$@")"

if [[ -n "${workflow_prompt}" && -n "${explicit_prompt}" ]]; then
	print_error "${agent_alias}${workflow_suffix} already includes a workflow prompt; do not pass another prompt"
	exit 1
fi

prompt="${explicit_prompt:-${workflow_prompt}}"
if [[ -z "${prompt}" ]]; then
	print_error "${agent_alias} requires a prompt or workflow alias"
	exit 1
fi

iteration=1
while true; do
	print_info "Iteration ${iteration}/${iteration_limit}"
	if run_agent_once "${agent_alias}" "${prompt}"; then
		if [[ "${iteration_limit}" != "unlimited" ]] && ((iteration >= iteration_limit)); then
			break
		fi
		iteration=$((iteration + 1))
		continue
	else
		status=$?
	fi

	print_error "Iteration ${iteration}/${iteration_limit} failed with exit code ${status}"
	exit "${status}"
done

print_success "Completed ${iteration}/${iteration_limit} iterations"
