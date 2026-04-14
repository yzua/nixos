#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

assert_true "hook file exists: build fields" test -f "${SCRIPT_DIR}/frida-hook-build-fields.js"
assert_true "hook file exists: file exists" test -f "${SCRIPT_DIR}/frida-hook-file-exists.js"
assert_true "hook file exists: shared prefs" test -f "${SCRIPT_DIR}/frida-hook-shared-prefs.js"
assert_true "hook file exists: url log" test -f "${SCRIPT_DIR}/frida-hook-url-log.js"
assert_true "hook file exists: cert pinner" test -f "${SCRIPT_DIR}/frida-bypass-certificate-pinner.js"

build_fields_contents="$(<"${SCRIPT_DIR}/frida-hook-build-fields.js")"
assert_contains "${build_fields_contents}" "Java.perform" "build fields hook uses Java.perform"

cert_bypass_contents="$(<"${SCRIPT_DIR}/frida-bypass-certificate-pinner.js")"
assert_contains "${cert_bypass_contents}" "CertificatePinner" "cert bypass hook targets CertificatePinner"

agents_prompt="$(<"${REPO_ROOT}/home-manager/modules/ai-agents/android-re/prompts/AGENTS.md")"
assert_contains "${agents_prompt}" "search the web, official docs, GitHub, CVE databases" "agent prompt allows external research"
assert_contains "${agents_prompt}" "CVE" "agent prompt allows CVE research"
assert_contains "${agents_prompt}" "use subagents" "agent prompt allows subagents"

tools_prompt="$(<"${REPO_ROOT}/home-manager/modules/ai-agents/android-re/prompts/TOOLS.md")"
assert_contains "${tools_prompt}" "Local Frida Hook Library" "tools prompt documents local hook library"
assert_contains "${tools_prompt}" "frida-hook-build-fields.js" "tools prompt references build fields hook"

workflow_prompt="$(<"${REPO_ROOT}/home-manager/modules/ai-agents/android-re/prompts/WORKFLOW.md")"
assert_contains "${workflow_prompt}" "hook library" "workflow prompt mentions hook library"

echo "All Android RE hook library tests passed."
