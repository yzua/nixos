#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGET="${SCRIPT_DIR}/agent-iter.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

assert_true "iter script is executable" test -x "${TARGET}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin" "${tmp_dir}/counts"
printf 'fake-zai-key\n' >"${tmp_dir}/zai_api_key"

cat >"${tmp_dir}/bin/agent-stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

tool="$(basename "$0")"
args_string="$(printf '%q ' "$@")"
printf '%s|ARGS=%s|ANTHROPIC_BASE_URL=%s|OPENCODE_CONFIG_DIR=%s\n' \
  "${tool}" \
  "${args_string% }" \
  "${ANTHROPIC_BASE_URL:-}" \
  "${OPENCODE_CONFIG_DIR:-}" >>"${ITER_LOG_FILE:?}"

count_file="${ITER_COUNT_DIR:?}/${tool}.count"
count=0
if [[ -f "${count_file}" ]]; then
  count="$(cat "${count_file}")"
fi
count=$((count + 1))
printf '%s\n' "${count}" >"${count_file}"

fail_tool="${ITER_FAIL_TOOL:-}"
fail_after="${ITER_FAIL_AFTER:-0}"
fail_code="${ITER_FAIL_CODE:-1}"
if [[ "${tool}" == "${fail_tool}" ]] && (( fail_after > 0 && count >= fail_after )); then
  exit "${fail_code}"
fi
EOF
chmod +x "${tmp_dir}/bin/agent-stub"
ln -s "${tmp_dir}/bin/agent-stub" "${tmp_dir}/bin/claude"
ln -s "${tmp_dir}/bin/agent-stub" "${tmp_dir}/bin/opencode"
ln -s "${tmp_dir}/bin/agent-stub" "${tmp_dir}/bin/codex"
ln -s "${tmp_dir}/bin/agent-stub" "${tmp_dir}/bin/gemini"

usage_output="$(bash "${TARGET}" 2>&1 || true)"
assert_contains "${usage_output}" "Usage: iter [count] <agent-alias> [prompt...]" "usage output is shown without arguments"

count_log="${tmp_dir}/counted.log"
: >"${count_log}"
count_output="$({
	PATH="${tmp_dir}/bin:${PATH}" \
		ITER_LOG_FILE="${count_log}" \
		ITER_COUNT_DIR="${tmp_dir}/counts" \
		ZAI_API_KEY_FILE="${tmp_dir}/zai_api_key" \
		bash "${TARGET}" 2 clglm "justsayhi"
} 2>&1)"

count_runs="$(wc -l <"${count_log}" | tr -d ' ')"
assert_eq "${count_runs}" "2" "counted mode runs exact iteration count"
count_log_contents="$(cat "${count_log}")"
assert_contains "${count_log_contents}" "claude|ARGS=--dangerously-skip-permissions --print justsayhi" "claude glm uses headless print mode"
assert_contains "${count_log_contents}" "ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic" "claude glm sets Z.AI base url"
assert_contains "${count_output}" "Iteration 2/2" "counted mode reports iteration progress"

opencode_log="${tmp_dir}/opencode.log"
: >"${opencode_log}"
opencode_output="$({
	PATH="${tmp_dir}/bin:${PATH}" \
		ITER_LOG_FILE="${opencode_log}" \
		ITER_COUNT_DIR="${tmp_dir}/counts" \
		bash "${TARGET}" 2 ocgem "hello world"
} 2>&1)"
opencode_log_contents="$(cat "${opencode_log}")"
assert_contains "${opencode_log_contents}" "opencode|ARGS=run hello\\ world" "opencode uses run subcommand for headless execution"
assert_contains "${opencode_log_contents}" "OPENCODE_CONFIG_DIR=${HOME}/.config/opencode-gemini" "opencode gemini sets profile config dir"
assert_contains "${opencode_output}" "Completed 2/2 iterations" "opencode counted loop completes successfully"

workflow_log="${tmp_dir}/workflow.log"
: >"${workflow_log}"
workflow_output="$({
	PATH="${tmp_dir}/bin:${PATH}" \
		ITER_LOG_FILE="${workflow_log}" \
		ITER_COUNT_DIR="${tmp_dir}/counts" \
		ZAI_API_KEY_FILE="${tmp_dir}/zai_api_key" \
		MARKDOWN_SYNC_PROMPT="sync docs please" \
		bash "${TARGET}" 2 clglmmd
} 2>&1)"
workflow_log_contents="$(cat "${workflow_log}")"
assert_contains "${workflow_log_contents}" "claude|ARGS=--dangerously-skip-permissions --print sync\\ docs\\ please" "workflow alias resolves built-in prompt"
assert_contains "${workflow_output}" "Completed 2/2 iterations" "workflow alias runs to completion"

codex_log="${tmp_dir}/codex.log"
: >"${codex_log}"
codex_output="$({
	PATH="${tmp_dir}/bin:${PATH}" \
		ITER_LOG_FILE="${codex_log}" \
		ITER_COUNT_DIR="${tmp_dir}/counts" \
		bash "${TARGET}" 1 cx "audit again"
} 2>&1)"
codex_log_contents="$(cat "${codex_log}")"
assert_contains "${codex_log_contents}" "codex|ARGS=exec --dangerously-bypass-approvals-and-sandbox audit\\ again" "codex uses exec subcommand for headless execution"
assert_not_contains "${codex_log_contents}" "--no-alt-screen" "codex headless mode skips TUI-only flags"
assert_contains "${codex_output}" "Completed 1/1 iterations" "codex counted loop completes successfully"

set +e
missing_prompt_output="$({
	PATH="${tmp_dir}/bin:${PATH}" \
		ITER_LOG_FILE="${tmp_dir}/missing.log" \
		ITER_COUNT_DIR="${tmp_dir}/counts" \
		ZAI_API_KEY_FILE="${tmp_dir}/zai_api_key" \
		bash "${TARGET}" 2 clglm
} 2>&1)"
missing_prompt_status=$?
set -e
assert_eq "${missing_prompt_status}" "1" "promptless interactive aliases are rejected"
assert_contains "${missing_prompt_output}" "requires a prompt or workflow alias" "promptless aliases get a helpful error"

unlimited_log="${tmp_dir}/unlimited.log"
: >"${unlimited_log}"
set +e
unlimited_output="$({
	PATH="${tmp_dir}/bin:${PATH}" \
		ITER_LOG_FILE="${unlimited_log}" \
		ITER_COUNT_DIR="${tmp_dir}/counts" \
		ITER_FAIL_TOOL="gemini" \
		ITER_FAIL_AFTER=3 \
		ITER_FAIL_CODE=17 \
		bash "${TARGET}" gem "keep going"
} 2>&1)"
unlimited_status=$?
set -e

unlimited_runs="$(wc -l <"${unlimited_log}" | tr -d ' ')"
assert_eq "${unlimited_status}" "17" "unlimited mode returns failing exit status"
assert_eq "${unlimited_runs}" "3" "unlimited mode repeats until failure"
assert_contains "${unlimited_output}" "Iteration 3/unlimited failed with exit code 17" "unlimited mode reports failure"

echo "All agent iter tests passed."
