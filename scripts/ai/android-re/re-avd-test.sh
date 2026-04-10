#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TARGET="${SCRIPT_DIR}/re-avd.sh"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin"

cat >"${tmp_dir}/bin/adb" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${tmp_dir}/bin/adb"

cat >"${tmp_dir}/bin/frida-ps" <<'EOF'
#!/usr/bin/env bash
sleep 30
EOF
chmod +x "${tmp_dir}/bin/frida-ps"

touch "${tmp_dir}/frida-server"
chmod +x "${tmp_dir}/frida-server"

usage_output="$(bash "${TARGET}" 2>&1 || true)"
assert_contains "${usage_output}" "Usage: re-avd.sh" "usage output is printed without arguments"

SECONDS=0
set +e
timeout_output="$(
	PATH="${tmp_dir}/bin:${PATH}" \
	FRIDA_BIN="${tmp_dir}/frida-server" \
	FRIDA_PS_BIN="${tmp_dir}/bin/frida-ps" \
	FRIDA_WAIT_TIMEOUT=1 \
	FRIDA_WAIT_RETRIES=1 \
	bash "${TARGET}" frida-start 2>&1
)"
timeout_status=$?
set -e
elapsed="${SECONDS}"

assert_eq "${timeout_status}" "1" "frida-start fails when Frida never becomes reachable"
assert_contains "${timeout_output}" "frida probe attempt 1/1 timed out after 1s" "frida-start reports bounded timeout attempts"
if (( elapsed >= 8 )); then
	echo "FAIL: frida-start probe should fail quickly (elapsed=${elapsed}s)"
	exit 1
fi
echo "PASS: frida-start probe fails quickly (elapsed=${elapsed}s)"

echo "All Android RE AVD tests passed."
