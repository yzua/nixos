# Bluetooth configuration module.

{
  config,
  lib,
  pkgsStable,
  ...
}:

let
  optionHelpers = import ./helpers/_option-helpers.nix { inherit lib; };
  inherit (optionHelpers) mkBoolOption;
in

{
  # Custom module options for Bluetooth configuration
  options.mySystem.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support with Blueman manager";

    powerOnBoot =
      mkBoolOption false true
        "Power on Bluetooth adapter automatically at boot. Disable on public networks for privacy.";
  };

  # Configuration applied when Bluetooth is enabled
  config = lib.mkIf config.mySystem.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      inherit (config.mySystem.bluetooth) powerOnBoot;

      # Security and privacy settings
      settings = {
        General = {
          Name = "Device"; # PRIVACY: Generic name instead of hostname
          DiscoverableTimeout = 30; # Limit discoverability window (seconds)
          PairableTimeout = 30; # Limit pairing window (seconds)
          FastConnectable = false; # Disable for power/security
          Experimental = false; # Disable experimental features
        };
        Policy = {
          AutoEnable = false; # Don't auto-enable adapter (privacy)
        };
      };
    };

    # Enable Blueman Bluetooth manager service (includes blueman package automatically)
    services.blueman.enable = true;

    # === Bluetooth Auto-Disable ===
    # Power off Bluetooth adapter when no devices are connected for 5 minutes.
    # Reduces attack surface (BLE scanning, BlueBorne-style exploits) when not in use.
    systemd.services.bluetooth-auto-disable = {
      description = "Auto-disable Bluetooth when no devices connected";
      after = [ "bluetooth.service" ];
      requires = [ "bluetooth.service" ];
      wantedBy = [ "default.target" ];
      path = [ pkgsStable.bluez ];
      script = ''
        while true; do
          sleep 300  # Check every 5 minutes
          # Get connected devices count
          connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
          if [[ "$connected" -eq 0 ]]; then
            bluetoothctl power off 2>/dev/null || true
          fi
        done
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # High-quality Bluetooth audio codecs (aptX, aptX-HD, LDAC, AAC, SBC-XQ)
    services.pipewire.wireplumber.extraConfig = {
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.codecs" = [
            "sbc"
            "sbc_xq"
            "aac"
            "ldac"
            "aptx"
            "aptx_hd"
          ];
        };
      };
    };

    environment.systemPackages = with pkgsStable; [
      libfreeaptx # aptX and aptX-HD codec support
    ];
  };
}
