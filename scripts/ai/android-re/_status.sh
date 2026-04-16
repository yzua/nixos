#!/usr/bin/env bash
# Health checks, diagnostics, and status reporting.
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/android-re/_helpers.sh

RE_ENABLE_PROXY="${RE_ENABLE_PROXY:-1}"
RE_SELINUX_PERMISSIVE="${RE_SELINUX_PERMISSIVE:-1}"
RE_SPOOF_DEVICE="${RE_SPOOF_DEVICE:-1}"
PROXY_HOST="${PROXY_HOST:-10.0.2.2}"

root_check() {
	adb_run shell 'su 0 sh -c id'
}

set_selinux_mode() {
	local mode="$1"
	local current

	current="$(adb_prop getenforce)"

	if [[ "${mode}" == "permissive" ]]; then
		if [[ "${current}" != "Permissive" ]]; then
			adb_run shell 'su 0 setenforce 0'
		fi
	else
		if [[ "${current}" != "Enforcing" ]]; then
			adb_run shell 'su 0 setenforce 1'
		fi
	fi

	log_success "SELinux mode: $(adb_prop getenforce)"
}

status() {
	_try_init_mitm_ca_vars || log_warning "mitmproxy CA not available (run 'doctor' for details)"
	log_info "avd: ${AVD_NAME}"
	if command -v emulator >/dev/null 2>&1; then
		if emulator -list-avds | grep -Fx "${AVD_NAME}" >/dev/null; then
			log_success "avd exists"
		else
			log_warning "avd missing"
		fi
	fi
	adb devices -l || true
	if emulator_online; then
		log_info "boot=$(adb_prop getprop sys.boot_completed)"
		log_info "device_identity=$(adb_prop getprop ro.product.manufacturer)/$(adb_prop getprop ro.product.model)"
		if adb shell 'su 0 sh -c id' >/dev/null 2>&1; then
			log_success "unattended root works"
		else
			log_warning "unattended root failed"
		fi
		if adb shell "ls ${MITM_CA_TARGET}" >/dev/null 2>&1; then
			log_success "mitmproxy system CA installed"
		else
			log_warning "mitmproxy system CA missing"
		fi
		log_info "proxy=$(adb_prop settings get global http_proxy)"
		warn_stale_host_proxy
		if [[ ! -x "${FRIDA_PS_BIN}" ]]; then
			FRIDA_PS_BIN="$(command -v frida-ps || true)"
		fi
		if [[ -n "${FRIDA_PS_BIN}" ]] && frida_host_probe; then
			log_success "frida reachable"
		else
			log_warning "frida not reachable"
		fi
	else
		log_warning "no emulator device online"
	fi
}

doctor() {
	_try_init_mitm_ca_vars || true
	for tool in adb emulator avdmanager sdkmanager mitmproxy mitmdump frida frida-ps apktool jadx sqlite3 unzip xz; do
		check_tool "$tool"
	done
	if [[ -d "${HOME}/.android/avd/${AVD_NAME}.avd" ]]; then
		log_success "avd directory exists"
	else
		log_warning "avd directory missing"
	fi
	if [[ -x "${FRIDA_BIN}" ]]; then
		log_success "frida server binary ready"
	else
		log_warning "frida server binary missing: ${FRIDA_BIN}"
	fi
	if [[ -f "${MITM_CA_SOURCE}" ]]; then
		log_success "mitmproxy CA source present"
	else
		log_warning "mitmproxy CA source missing: ${MITM_CA_SOURCE}"
	fi
}

cert_check() {
	init_mitm_ca_vars
	adb_run shell "ls -l ${MITM_CA_TARGET}"
	adb_run shell "ls -l /apex/com.android.conscrypt/cacerts/${MITM_CA_HASH}"
}
