#!/usr/bin/env bash
# Shared agent registry: alias definitions, command mappings for both
# launcher (interactive) and iter (headless) modes, workflow suffix resolution,
# ZAI key handling.
#
# Single source of truth for all agent aliases.  Adding a new alias only
# requires editing the _def calls below (plus any fzf picker menus in
# agent-launcher.sh).
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
RUNTIME_PERFORMANCE_PROMPT="${RUNTIME_PERFORMANCE_PROMPT:-}"
MARKDOWN_SYNC_PROMPT="${MARKDOWN_SYNC_PROMPT:-}"

# All recognized workflow suffixes.
WORKFLOW_SUFFIXES=(cm rf fx sa du bp rp md)

# Workflow metadata: suffix -> "label|env_var"
declare -A WORKFLOW_MAP=(
  [cm]="commit split (cm) — Splits working tree into logical commits with validated, minimal staging.|COMMIT_SPLIT_PROMPT"
  [rf]="refactor maintainability (rf) — Improves structure and clarity without changing behavior, APIs, or workflows.|REFACTOR_MAINTAINABILITY_PROMPT"
  [fx]="bugfix root cause (fx) — Reproduces bugs, proves root cause, fixes minimally, validates regressions afterward.|BUGFIX_ROOT_CAUSE_PROMPT"
  [sa]="security audit (sa) — Finds evidence-backed security weaknesses across code, configs, dependencies, infrastructure surfaces.|SECURITY_AUDIT_PROMPT"
  [du]="dependency upgrade (du) — Upgrades dependencies safely, handles breaking changes, validates compatibility, reports blockers.|DEPENDENCY_UPGRADE_PROMPT"
  [bp]="build performance (bp) — Measures bottlenecks, applies low-risk optimizations, compares before-and-after performance evidence clearly.|BUILD_PERFORMANCE_PROMPT"
  [rp]="runtime performance (rp) — Measures real code-path bottlenecks, applies low-risk optimizations, and verifies before-and-after latency, throughput, or memory gains.|RUNTIME_PERFORMANCE_PROMPT"
  [md]="markdown sync (md) — Synchronizes documentation with repository reality, removing drift, ambiguity, stale instructions.|MARKDOWN_SYNC_PROMPT"
)

# Human-readable labels for workflow suffixes.
workflow_label() {
  local entry="${WORKFLOW_MAP[$1]:-}"
  [[ -n "$entry" ]] || return 1
  echo "${entry%%|*}"
}

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

# Single-source definition: each alias registers both interactive and headless commands.
# Usage: _def ALIAS ENV_MARKER INTERACTIVE_CMD HEADLESS_CMD
_def() {
  AGENT_REGISTRY["$1"]="$2|$3"
  AGENT_ITER_REGISTRY["$1"]="$2|$4"
}

declare -A AGENT_REGISTRY=()
# shellcheck disable=SC2034
declare -A AGENT_ITER_REGISTRY=()

# Claude Code
_def cl    -    "claude --dangerously-skip-permissions"                          "claude --print"
_def clu   -    "claude --dangerously-skip-permissions"                          "claude --dangerously-skip-permissions --print"
_def ocl   -    "claude --dangerously-skip-permissions --model opus"             "claude --model opus --print"
_def hcl   -    "claude --dangerously-skip-permissions --model haiku"            "claude --model haiku --print"
_def clglm ZAI  "claude --dangerously-skip-permissions"                          "claude --dangerously-skip-permissions --print"

# Codex
_def cx    -    "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox"                                            "codex exec --dangerously-bypass-approvals-and-sandbox"
_def cxu   -    "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox"                                            "codex exec --dangerously-bypass-approvals-and-sandbox"
_def lcx   -    "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"low\"'"       "codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"low\"'"
_def mcx   -    "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"medium\"'"     "codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"medium\"'"
_def hcx   -    "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"high\"'"       "codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"high\"'"
_def xcx   -    "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"xhigh\"'"      "codex exec --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort=\"xhigh\"'"

# OpenCode (default and profiles)
_def oc      -                                      "opencode"                       "opencode run"
_def ocglm   "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-glm"     "opencode"         "opencode run"
_def ocgem   "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gemini"  "opencode"         "opencode run"
_def ocgpt   "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt"    "opencode"         "opencode run"
_def locgpt  "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt"    "opencode --model openai/gpt-5.4-spark"     "opencode run --model openai/gpt-5.4-spark"
_def mocgpt  "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt"    "opencode --model openai/gpt-5.4"           "opencode run --model openai/gpt-5.4"
_def xocgpt  "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt"    "opencode --model openai/gpt-5.1-codex-max" "opencode run --model openai/gpt-5.1-codex-max"
_def ocs     "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-sonnet" "opencode"         "opencode run"
_def oczen   "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-zen"    "opencode"         "opencode run"

# Gemini
_def gem   -    "gemini --approval-mode=yolo"         "gemini --approval-mode=yolo --prompt"

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
  local entry="${WORKFLOW_MAP[$1]:-}"
  if [[ -n "$entry" ]]; then
    local env_var="${entry##*|}"
    printf '%s\n' "${!env_var:-}"
  else
    printf '%s\n' ""
  fi
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
