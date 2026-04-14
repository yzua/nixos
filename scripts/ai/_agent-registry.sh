#!/usr/bin/env bash
# Shared agent registry: alias definitions, command mappings for both
# launcher (interactive) and iter (headless) modes, workflow suffix resolution,
# ZAI key handling.
#
# Single source of truth for all agent aliases.  Adding a new alias only
# requires editing this file (plus any fzf picker menus in agent-launcher.sh).
#
# Source this file from agent-launcher.sh and agent-iter.sh.
# Requires: logging.sh sourced before this file.

# --- Workflow prompt env vars (set defaults for set -u safety) ---
COMMIT_SPLIT_PROMPT="${COMMIT_SPLIT_PROMPT:-}"
REFACTOR_MAINTAINABILITY_PROMPT="${REFACTOR_MAINTAINABILITY_PROMPT:-}"
BUGFIX_ROOT_CAUSE_PROMPT="${BUGFIX_ROOT_CAUSE_PROMPT:-}"
SECURITY_AUDIT_PROMPT="${SECURITY_AUDIT_PROMPT:-}"
DEPENDENCY_UPGRADE_PROMPT="${DEPENDENCY_UPGRADE_PROMPT:-}"
BUILD_PERFORMANCE_PROMPT="${BUILD_PERFORMANCE_PROMPT:-}"
MARKDOWN_SYNC_PROMPT="${MARKDOWN_SYNC_PROMPT:-}"

# All recognized workflow suffixes.
WORKFLOW_SUFFIXES=(cm rf fx sa du bp md)

# --- Agent registries --------------------------------------------------------
#
# AGENT_REGISTRY:  alias -> interactive/launcher command
# AGENT_ITER_REGISTRY:  alias -> headless/iter command
#
# Format per entry:  "env_marker|command_prefix"
#   env_marker:
#     "-"   = no extra env vars
#     "ZAI" = resolve Z.AI API vars at runtime (via zai_claude_env)
#     otherwise = space-separated KEY=VAL pairs (e.g. "FOO=bar BAZ=qux")
#   command_prefix:
#     Full command with flags for the given mode.  Prompt is appended
#     positionally (except in launcher mode where OpenCode uses --prompt).

declare -A AGENT_REGISTRY=(
  # Claude Code
  [cl]="-|claude --dangerously-skip-permissions"
  [clu]="-|claude --dangerously-skip-permissions"
  [ocl]="-|claude --dangerously-skip-permissions --model opus"
  [hcl]="-|claude --dangerously-skip-permissions --model haiku"
  [clglm]="ZAI|claude --dangerously-skip-permissions"

  # Codex
  [cx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox"
  [cxu]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox"
  [lcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"low\"'"
  [mcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"medium\"'"
  [hcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"high\"'"
  [xcx]="-|codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"xhigh\"'"

  # OpenCode (default and profiles)
  [oc]="-|opencode"
  [ocglm]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-glm|opencode"
  [ocgem]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gemini|opencode"
  [ocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode"
  [locgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode --model openai/gpt-5.4-spark"
  [mocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode --model openai/gpt-5.4"
  [xocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode --model openai/gpt-5.1-codex-max"
  [ocs]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-sonnet|opencode"
  [oczen]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-zen|opencode"

  # Gemini
  [gem]="-|gemini --approval-mode=yolo"
)

# shellcheck disable=SC2034
declare -A AGENT_ITER_REGISTRY=(
  # Claude Code (headless: --print mode)
  [cl]="-|claude --print"
  [clu]="-|claude --dangerously-skip-permissions --print"
  [ocl]="-|claude --model opus --print"
  [hcl]="-|claude --model haiku --print"
  [clglm]="ZAI|claude --dangerously-skip-permissions --print"

  # Codex (headless: exec subcommand)
  [cx]="-|codex exec --dangerously-bypass-approvals-and-sandbox"
  [cxu]="-|codex exec --dangerously-bypass-approvals-and-sandbox"
  [lcx]="-|codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"low\"'"
  [mcx]="-|codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"medium\"'"
  [hcx]="-|codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"high\"'"
  [xcx]="-|codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"xhigh\"'"

  # OpenCode (headless: run subcommand)
  [oc]="-|opencode run"
  [ocglm]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-glm|opencode run"
  [ocgem]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gemini|opencode run"
  [ocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode run"
  [locgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode run --model openai/gpt-5.4-spark"
  [mocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode run --model openai/gpt-5.4"
  [xocgpt]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt|opencode run --model openai/gpt-5.1-codex-max"
  [ocs]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-sonnet|opencode run"
  [oczen]="OPENCODE_CONFIG_DIR=$HOME/.config/opencode-zen|opencode run"

  # Gemini (headless: --prompt flag is part of command_prefix)
  [gem]="-|gemini --approval-mode=yolo --prompt"
)

# --- Supported base aliases ---

is_supported_base_alias() {
  [[ -v AGENT_REGISTRY[$1] ]]
}

# Z.AI API key resolution.
zai_key_path() {
  printf '%s\n' "${ZAI_API_KEY_FILE:-/run/secrets/zai_api_key}"
}

require_secret_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    print_error "${path} not found. Run 'just nixos' to decrypt secrets."
    exit 1
  fi
}

# Read and return the ZAI API key (exits on missing file).
zai_key() {
  local key_path
  key_path="$(zai_key_path)"
  require_secret_file "${key_path}"
  cat "${key_path}"
}

# Common Z.AI environment variables for claude --dangerously-skip-permissions.
# Outputs KEY=VAL lines (one per line) for consumption by env.
zai_claude_env() {
  local key
  key="$(zai_key)"
  printf '%s\n' "ANTHROPIC_AUTH_TOKEN=${key}"
  printf '%s\n' "ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic"
  printf '%s\n' "API_TIMEOUT_MS=3000000"
  printf '%s\n' "ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-5-turbo"
  printf '%s\n' "ANTHROPIC_DEFAULT_SONNET_MODEL=glm-5.1"
  printf '%s\n' "ANTHROPIC_DEFAULT_OPUS_MODEL=glm-5.1"
}

# --- Workflow suffix resolution ---

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

# --- Alias/suffix splitting ---

split_alias_suffix() {
  local alias_name="$1"
  local suffix
  local candidate

  for suffix in "${WORKFLOW_SUFFIXES[@]}"; do
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
