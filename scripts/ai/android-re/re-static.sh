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
		check_tool "$tool"
	done
}

usage() {
	cat <<'EOF'
Usage: re-static.sh <command> [args]

Commands:
  prepare APK_PATH          Unpack the APK with apktool and jadx into ~/.cache/android-re/out/
  hashes APK_PATH           Print md5 and sha256 for the APK
  inventory                 Show available static-analysis tools
  diff OLD_NAME NEW_NAME    Compare two previously-prepared APK analysis outputs
EOF
}

diff_analysis() {
	local old_name="$1"
	local new_name="$2"
	local old_dir="${OUTPUT_ROOT}/${old_name}"
	local new_dir="${OUTPUT_ROOT}/${new_name}"

	[[ -d "${old_dir}" ]] || error_exit "old analysis not found: ${old_dir}"
	[[ -d "${new_dir}" ]] || error_exit "new analysis not found: ${new_dir}"

	log_info "comparing ${old_name} -> ${new_name}"

	# Hash comparison
	if [[ -f "${old_dir}/sha256.txt" && -f "${new_dir}/sha256.txt" ]]; then
		local old_hash new_hash
		old_hash="$(awk '{print $1}' "${old_dir}/sha256.txt")"
		new_hash="$(awk '{print $1}' "${new_dir}/sha256.txt")"
		if [[ "${old_hash}" == "${new_hash}" ]]; then
			log_info "SHA-256: identical (${old_hash:0:16}...)"
		else
			log_info "SHA-256 changed: ${old_hash:0:16}... -> ${new_hash:0:16}..."
		fi
	fi

	# Manifest permission changes
	local old_manifest new_manifest
	old_manifest="${old_dir}/apktool/AndroidManifest.xml"
	new_manifest="${new_dir}/apktool/AndroidManifest.xml"
	if [[ -f "${old_manifest}" && -f "${new_manifest}" ]]; then
		local old_perms new_perms
		old_perms="$(grep -oP 'android:name="\K[^"]+' "${old_manifest}" | grep -i permission | sort -u || true)"
		new_perms="$(grep -oP 'android:name="\K[^"]+' "${new_manifest}" | grep -i permission | sort -u || true)"
		if [[ "${old_perms}" != "${new_perms}" ]]; then
			log_info "manifest permissions changed:"
			diff <(echo "${old_perms}") <(echo "${new_perms}") || true
		else
			log_info "manifest permissions: unchanged"
		fi
	fi

	# Native library changes
	local old_libs new_libs
	old_libs="$(find "${old_dir}/apktool/lib" -name '*.so' -exec basename {} \; 2>/dev/null | sort -u || true)"
	new_libs="$(find "${new_dir}/apktool/lib" -name '*.so' -exec basename {} \; 2>/dev/null | sort -u || true)"
	if [[ "${old_libs}" != "${new_libs}" ]]; then
		log_info "native libraries changed:"
		diff <(echo "${old_libs}") <(echo "${new_libs}") || true
	else
		log_info "native libraries: unchanged ($(echo "${new_libs}" | wc -l) libs)"
	fi

	# Java class count changes
	local old_classes new_classes
	old_classes="$(find "${old_dir}/jadx/sources" -name '*.java' 2>/dev/null | wc -l || echo 0)"
	new_classes="$(find "${new_dir}/jadx/sources" -name '*.java' 2>/dev/null | wc -l || echo 0)"
	log_info "Java classes: ${old_classes} -> ${new_classes}"

	log_success "diff complete"
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
	diff)
		[[ -n "${2:-}" ]] || error_exit "diff requires OLD_NAME"
		[[ -n "${3:-}" ]] || error_exit "diff requires NEW_NAME"
		diff_analysis "$2" "$3"
		;;
	*)
		usage
		exit 1
		;;
	esac
}

main "$@"
