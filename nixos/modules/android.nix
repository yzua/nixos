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
  # Libraries the SDK emulator needs from the host (not bundled)
  emulatorLibs = with pkgs; [
    libpulseaudio # libpulse.so.0
    libxcb-cursor # libxcb-cursor.so.0 (Qt xcb platform plugin)
    libsm # libSM.so.6 (X Session Management)
    libice # libICE.so.6 (Inter-Client Exchange)
  ];
  # Wrapper for the SDK emulator — provides missing shared libs at runtime
  emulatorWrapped = pkgs.writeShellScriptBin "emulator" ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath emulatorLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec ${sdkRoot}/emulator/emulator "$@"
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
