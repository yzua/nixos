#!/usr/bin/env bash
# Device identity spoofing (apply/restore).
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/android-re/_helpers.sh

spoof_device() {
	local changed=0 failed=0
	log_info "spoofing device identity to look like a real ${SPOOF_DEVICE_MODEL}"

	# Resolve Magisk binary — it acts as a multi-call binary (resetprop, magisk, su, etc.)
	# On this AVD, Magisk is installed as an app; the binary lives under the app data directory.
	local resetprop_bin
	resetprop_bin="$(adb_prop 'su 0 sh -c "ls /data/user/0/com.android.shell/Magisk/lib/x86_64/magisk 2>/dev/null || ls /data/adb/magisk/magisk 2>/dev/null || which magisk 2>/dev/null || echo """')"
	if [[ -z "${resetprop_bin}" ]]; then
		log_error "cannot find Magisk binary for resetprop"
		return 1
	fi
	log_info "using Magisk binary: ${resetprop_bin}"

	# Apply system properties via Magisk resetprop (bypasses ro.* read-only)
	local entry prop value old
	for entry in "${SPOOF_PROPS[@]}"; do
		IFS='|' read -r prop value <<<"${entry}"
		old="$(adb_prop "su 0 getprop ${prop}")"
		if [[ "${old}" == "${value}" ]]; then
			continue
		fi
		if adb shell "su 0 ${resetprop_bin} resetprop ${prop} '${value}'" >/dev/null 2>&1; then
			changed=$((changed + 1))
		else
			log_warning "resetprop failed: ${prop}"
			failed=$((failed + 1))
		fi
	done

	# Hide emulator-indicator files (goldfish, qemu pipes)
	local emu_file
	for emu_file in "${SPOOF_HIDE_FILES[@]}"; do
		adb shell "su 0 sh -c 'if [ -e ${emu_file} ]; then mv ${emu_file} ${emu_file}.hidden; fi'" >/dev/null 2>&1 || true
	done

	# Kill emulator-specific services that aren't needed for app execution
	local svc
	for svc in "${SPOOF_STOP_SERVICES[@]}"; do
		adb shell "su 0 sh -c 'stop ${svc} 2>/dev/null || true'" >/dev/null 2>&1 || true
	done

	log_success "device spoof applied (${changed} props changed, ${failed} failed, ${#SPOOF_HIDE_FILES[@]} files hidden, ${#SPOOF_STOP_SERVICES[@]} services stopped)"

	# Quick verification
	log_info "identity check: hardware=$(adb_prop getprop ro.hardware) model=$(adb_prop getprop ro.product.model) characteristics=$(adb_prop getprop ro.build.characteristics)"
}

unspoof_device() {
	log_info "restoring original emulator identity"

	local emu_file
	for emu_file in "${SPOOF_HIDE_FILES[@]}"; do
		adb shell "su 0 sh -c 'if [ -e ${emu_file}.hidden ]; then mv ${emu_file}.hidden ${emu_file}; fi'" >/dev/null 2>&1 || true
	done

	# resetprop reverts are unreliable; recommend reboot for full restore
	log_warning "system property changes persist until emulator reboot"
	log_success "hidden files restored"
}
