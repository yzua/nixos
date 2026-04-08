# Android device and emulator support (ADB, Fastboot, Android Studio/AVD).
# The SDK emulator binary (from Google) bundles its own Qt but needs system
# libraries at load time. We wrap it with LD_LIBRARY_PATH.

{
  pkgs,
  pkgsStable,
  lib,
  user,
  ...
}:

let
  sdkRoot = "/home/${user}/Android/Sdk";
  nvidiaVulkanIcd = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  sdkBuildToolsDir = "${sdkRoot}/build-tools";
  # Libraries the SDK emulator needs from the host (not bundled)
  emulatorLibs = with pkgs; [
    libpulseaudio # libpulse.so.0
    libxcb-cursor # libxcb-cursor.so.0 (Qt xcb platform plugin)
    libsm # libSM.so.6 (X Session Management)
    libice # libICE.so.6 (Inter-Client Exchange)
  ];
  # Wrapper for the SDK emulator — provides missing shared libs at runtime
  emulatorWrapped = pkgs.writeShellScriptBin "emulator" ''
    gpuMode="''${ANDROID_EMULATOR_GPU_MODE:-auto}"
    if [[ "$gpuMode" == "auto" && -f "${nvidiaVulkanIcd}" ]]; then
      gpuMode="host"
    fi
    export LD_LIBRARY_PATH="${lib.makeLibraryPath emulatorLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export QT_QPA_PLATFORM="''${QT_QPA_PLATFORM:-xcb}"

    case "$gpuMode" in
      software|swiftshader|swangle|lavapipe)
        export LIBGL_ALWAYS_SOFTWARE="''${LIBGL_ALWAYS_SOFTWARE:-1}"
        export __EGL_VENDOR_LIBRARY_FILENAMES="''${__EGL_VENDOR_LIBRARY_FILENAMES:-/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json}"
        unset LIBVA_DRIVER_NAME
        unset GBM_BACKEND
        unset __GLX_VENDOR_LIBRARY_NAME
        unset NVD_BACKEND
        ;;
      *)
        unset LIBGL_ALWAYS_SOFTWARE
        unset __EGL_VENDOR_LIBRARY_FILENAMES
        if [[ -f "${nvidiaVulkanIcd}" ]]; then
          export __GLX_VENDOR_LIBRARY_NAME="''${__GLX_VENDOR_LIBRARY_NAME:-nvidia}"
          export VK_ICD_FILENAMES="''${VK_ICD_FILENAMES:-${nvidiaVulkanIcd}}"
          export VK_LOADER_LAYERS_DISABLE="''${VK_LOADER_LAYERS_DISABLE:-~implicit~explicit}"
        fi
        ;;
    esac

    unset MOZ_ENABLE_WAYLAND
    exec ${sdkRoot}/emulator/emulator "$@"
  '';
  buildToolsWrapped =
    tool:
    pkgs.writeShellScriptBin tool ''
      build_tools_dir="$(find ${sdkBuildToolsDir} -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -n1)"
      if [[ -z "$build_tools_dir" || ! -x "$build_tools_dir/${tool}" ]]; then
        echo "missing Android SDK build-tools executable: ${tool}" >&2
        exit 1
      fi
      case "${tool}" in
        apksigner)
          exec ${pkgs.bash}/bin/bash "$build_tools_dir/${tool}" "$@"
          ;;
        *)
          exec "$build_tools_dir/${tool}" "$@"
          ;;
      esac
    '';
in
{
  environment = {
    systemPackages = [
      pkgsStable.android-tools
      pkgs.android-studio
      pkgs.libpulseaudio
      pkgs.libxcb-cursor
      pkgs.libsm
      pkgs.libice
      emulatorWrapped
      (buildToolsWrapped "aapt")
      (buildToolsWrapped "aapt2")
      (buildToolsWrapped "apksigner")
      (buildToolsWrapped "zipalign")
    ];

    sessionVariables = {
      ANDROID_HOME = sdkRoot;
      ANDROID_SDK_ROOT = sdkRoot;
    };

    shellInit = ''
      # Android SDK tools (manually installed, not via Nix)
      export PATH="${sdkRoot}/cmdline-tools/latest/bin:${sdkRoot}/platform-tools:$PATH"
      # Note: emulator is wrapped by emulatorWrapped (Nix bin), do not add SDK emulator/ to PATH
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", GROUP="users"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ENV{ID_MM_DEVICE_IGNORE}="1"
  '';

  # TPROXY kernel modules for mitmproxy transparent proxy mode
  boot.kernelModules = [
    "xt_TPROXY"
    "nf_tproxy_ipv4"
    "nf_tproxy_ipv6"
    "nf_conntrack"
  ];
}
