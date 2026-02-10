# Bluetooth configuration module.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Custom module options for Bluetooth configuration
  options.mySystem.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support with Blueman manager";

    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Power on Bluetooth adapter automatically at boot. Disable on public networks for privacy.";
    };
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

    environment.systemPackages = with pkgs; [
      libfreeaptx # aptX and aptX-HD codec support
    ];
  };
}
