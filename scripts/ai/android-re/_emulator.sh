#!/usr/bin/env bash
# Emulator lifecycle management (start, stop, boot wait).
# shellcheck source=scripts/lib/logging.sh
# shellcheck source=scripts/ai/android-re/_helpers.sh

MESA_EGL_VENDOR_FILE="${MESA_EGL_VENDOR_FILE:-/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json}"
NVIDIA_VULKAN_ICD="${NVIDIA_VULKAN_ICD:-/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json}"
EMU_GPU_MODE="${EMU_GPU_MODE:-auto}"
EMU_HEADLESS="${EMU_HEADLESS:-0}"
EMU_DISABLE_VULKAN="${EMU_DISABLE_VULKAN:-0}"
EMU_DISABLE_HARDWARE_DECODER="${EMU_DISABLE_HARDWARE_DECODER:-1}"
BOOT_WAIT_TIMEOUT="${BOOT_WAIT_TIMEOUT:-180}"

list_emulator_pids() {
	pgrep -f "qemu-system-.*@${AVD_NAME}([[:space:]]|\$)" || true
}

show_runtime_log_tail() {
	if [[ -f "${RUNTIME_LOG}" ]]; then
		log_warning "recent emulator log from ${RUNTIME_LOG}:"
		tail -n 20 "${RUNTIME_LOG}" >&2 || true
	fi
}

stop_stale_emulator_processes() {
	local pids

	pids="$(list_emulator_pids)"
	if [[ -z "${pids}" ]]; then
		return 0
	fi

	log_warning "stopping stale emulator process(es) for ${AVD_NAME}: ${pids//$'\n'/ }"
	while IFS= read -r pid; do
		[[ -n "${pid}" ]] || continue
		kill "${pid}" 2>/dev/null || true
	done <<<"${pids}"

	for _ in $(seq 1 10); do
		if [[ -z "$(list_emulator_pids)" ]]; then
			log_success "stale emulator process cleanup complete"
			return 0
		fi
		sleep 1
	done

	pids="$(list_emulator_pids)"
	if [[ -n "${pids}" ]]; then
		log_warning "forcing stale emulator process shutdown for ${AVD_NAME}: ${pids//$'\n'/ }"
		while IFS= read -r pid; do
			[[ -n "${pid}" ]] || continue
			kill -9 "${pid}" 2>/dev/null || true
		done <<<"${pids}"
	fi
}

wait_boot() {
	if ! timeout "${BOOT_WAIT_TIMEOUT}" adb wait-for-device >/dev/null 2>&1; then
		log_error "emulator did not register with adb within ${BOOT_WAIT_TIMEOUT}s"
		show_runtime_log_tail
		return 1
	fi

	local waited=0
	until [[ "$(adb_prop getprop sys.boot_completed)" == "1" ]]; do
		if ((waited >= BOOT_WAIT_TIMEOUT)); then
			log_error "emulator boot did not complete within ${BOOT_WAIT_TIMEOUT}s"
			show_runtime_log_tail
			return 1
		fi
		sleep 2
		waited=$((waited + 2))
	done
}

start_emulator() {
	need_cmd emulator
	local -a emulator_args
	local -a env_args
	local qt_platform="${QT_QPA_PLATFORM:-xcb}"
	local headless="${EMU_HEADLESS}"
	local gpu_mode="${EMU_GPU_MODE}"
	stop_all_emulators
	log_info "starting emulator ${AVD_NAME}"

	if [[ "${gpu_mode}" == "auto" && -f "${NVIDIA_VULKAN_ICD}" ]]; then
		gpu_mode="host"
		log_info "detected NVIDIA Vulkan ICD; preferring host GPU mode over emulator auto"
	fi

	emulator_args=(
		@"${AVD_NAME}"
		-writable-system
		-no-snapshot
		-no-metrics
		-gpu "${gpu_mode}"
		-netdelay none
		-netspeed full
	)

	if [[ "${EMU_DISABLE_HARDWARE_DECODER}" == "1" ]]; then
		emulator_args+=(-feature -HardwareDecoder)
	fi

	if [[ "${EMU_DISABLE_VULKAN}" == "1" ]]; then
		emulator_args+=(-feature -Vulkan)
	fi

	if [[ "${headless}" != "1" && -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
		headless="1"
		log_warning "no DISPLAY or WAYLAND_DISPLAY in this shell; falling back to headless emulator mode"
	fi

	if [[ "${headless}" == "1" ]]; then
		qt_platform="offscreen"
		emulator_args+=(-no-window)
	elif [[ -z "${DISPLAY:-}" && -n "${WAYLAND_DISPLAY:-}" && -z "${QT_QPA_PLATFORM:-}" ]]; then
		qt_platform="wayland;xcb"
	fi

	env_args=(
		QT_QPA_PLATFORM="${qt_platform}"
		ANDROID_EMULATOR_GPU_MODE="${gpu_mode}"
	)

	if [[ "${gpu_mode}" != "software" && -f "${NVIDIA_VULKAN_ICD}" ]]; then
		env_args+=(
			__GLX_VENDOR_LIBRARY_NAME="${__GLX_VENDOR_LIBRARY_NAME:-nvidia}"
			VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-${NVIDIA_VULKAN_ICD}}"
			VK_LOADER_LAYERS_DISABLE="${VK_LOADER_LAYERS_DISABLE:-~implicit~explicit}"
		)
	fi

	nohup env "${env_args[@]}" emulator "${emulator_args[@]}" >"${RUNTIME_LOG}" 2>&1 &
	log_info "emulator gpu=${gpu_mode} headless=${headless} disable_vulkan=${EMU_DISABLE_VULKAN} disable_hw_decoder=${EMU_DISABLE_HARDWARE_DECODER}"
	log_success "emulator started; log=${RUNTIME_LOG}"
	wait_boot
	log_success "emulator boot complete"
	warn_stale_host_proxy
}

stop_emulator() {
	if emulator_online; then
		log_info "stopping emulator"
		adb_run emu kill || true
	else
		log_warning "no running emulator detected"
	fi
}

stop_all_emulators() {
	local serial found=0
	while IFS= read -r serial; do
		[[ -n "${serial}" ]] || continue
		found=1
		log_info "stopping running emulator ${serial}"
		adb -s "${serial}" emu kill || true
	done < <(adb devices 2>/dev/null | grep '^emulator-' | cut -f1)

	if [[ "${found}" == "0" ]]; then
		log_warning "no running emulators detected"
	fi

	stop_stale_emulator_processes

	for _ in $(seq 1 20); do
		if ! emulator_online && [[ -z "$(list_emulator_pids)" ]]; then
			log_success "all running emulators stopped"
			return 0
		fi
		sleep 1
	done

	log_warning "some emulators may still be shutting down"
}

warn_stale_host_proxy() {
	local proxy host port
	proxy="$(adb_prop settings get global http_proxy)"

	if [[ -z "${proxy}" || "${proxy}" == ":0" || "${proxy}" == "null" ]]; then
		return 0
	fi

	host="${proxy%%:*}"
	port="${proxy##*:}"

	if [[ "${host}" != "10.0.2.2" || ! "${port}" =~ ^[0-9]+$ ]]; then
		return 0
	fi

	if ! command -v ss >/dev/null 2>&1; then
		log_warning "emulator proxy is set to ${proxy}; install 'ss' host-side to verify the listener"
		return 0
	fi

	if ! port_in_use "${port}"; then
		log_warning "emulator proxy points to ${proxy}, but nothing is listening on host port ${port}"
		log_warning "run 'bash scripts/ai/android-re/re-avd.sh proxy-clear' or start mitmdump on ${port}"
	fi
}
