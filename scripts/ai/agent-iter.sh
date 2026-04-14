#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/ai/_agent-registry.sh
source "${SCRIPT_DIR}/_agent-registry.sh"

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

# require_secret_file provided by _agent-registry.sh

# zai_key_path provided by _agent-registry.sh

# is_supported_base_alias provided by _agent-registry.sh

# split_alias_suffix provided by _agent-registry.sh

# resolve_workflow_prompt provided by _agent-registry.sh

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

# Run a single headless iteration of an agent using AGENT_ITER_REGISTRY.
run_agent_once() {
	local alias_name="$1"
	local prompt="$2"

	local entry="${AGENT_ITER_REGISTRY[$alias_name]:-}"
	if [[ -z "$entry" ]]; then
		print_error "Unsupported alias for iter: ${alias_name}"
		exit 1
	fi

	local env_marker="${entry%%|*}"
	local command="${entry#*|}"

	# Resolve env vars and execute
	case "$env_marker" in
	"-")
		# shellcheck disable=SC2086
		$command "${prompt}"
		;;
	"ZAI")
		# shellcheck disable=SC2086,SC2046
		env $(zai_claude_env) $command "${prompt}"
		;;
	*)
		# shellcheck disable=SC2086
		env $env_marker $command "${prompt}"
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
