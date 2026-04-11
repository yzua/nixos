#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/logging.sh"

OUTPUT_ROOT="${OUTPUT_ROOT:-${HOME}/.cache/android-re/out}"

# shellcheck source=scripts/ai/android-re/_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

app_name_from_apk() {
	basename "$1" .apk
}

prepare() {
	local apk="$1"
	need_file "${apk}"
	need_cmd apktool
	need_cmd jadx

	local name
	name="$(app_name_from_apk "${apk}")"
	local out_dir="${OUTPUT_ROOT}/${name}"
	local apktool_dir="${out_dir}/apktool"
	local jadx_dir="${out_dir}/jadx"

	mkdir -p "${out_dir}"
	log_info "preparing static analysis output under ${out_dir}"
	sha256sum "${apk}" >"${out_dir}/sha256.txt"
	md5sum "${apk}" >"${out_dir}/md5.txt"
	stat "${apk}" >"${out_dir}/metadata.txt"
	apktool d -f "${apk}" -o "${apktool_dir}" >/dev/null
	jadx -d "${jadx_dir}" "${apk}" >/dev/null
	log_success "apktool output: ${apktool_dir}"
	log_success "jadx output: ${jadx_dir}"
}

hashes() {
	local apk="$1"
	need_file "${apk}"
	sha256sum "${apk}"
	md5sum "${apk}"
}

inventory() {
	for tool in apktool jadx jadx-gui ghidra binwalk radare2 cutter scrcpy; do
		if command -v "$tool" >/dev/null 2>&1; then
			log_success "tool present: ${tool} -> $(command -v "$tool")"
		else
			log_warning "tool missing: ${tool}"
		fi
	done
}

usage() {
	cat <<'EOF'
Usage: re-static.sh <command> [args]

Commands:
  prepare APK_PATH   Unpack the APK with apktool and jadx into ~/.cache/android-re/out/
  hashes APK_PATH    Print md5 and sha256 for the APK
  inventory          Show available static-analysis tools
EOF
}

main() {
	local cmd="${1:-}"
	case "${cmd}" in
	prepare)
		[[ -n "${2:-}" ]] || error_exit "prepare requires APK_PATH"
		prepare "$2"
		;;
	hashes)
		[[ -n "${2:-}" ]] || error_exit "hashes requires APK_PATH"
		hashes "$2"
		;;
	inventory)
		inventory
		;;
	*)
		usage
		exit 1
		;;
	esac
}

main "$@"
