# NVIDIA Optimus (hybrid graphics) for ThinkPad.
{ config, lib, ... }:

{
  options.mySystem.nvidia = {
    intelBusId = lib.mkOption {
      type = lib.types.str;
      default = "PCI:0:2:0:0";
      example = "PCI:0:2:0:0";
      description = "Intel GPU PCI bus ID (format: PCI:bus:device:function).";
    };

    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      default = "PCI:2:0:0:0";
      example = "PCI:2:0:0:0";
      description = "NVIDIA GPU PCI bus ID (format: PCI:bus:device:function).";
    };
  };

  config = {
    hardware.nvidia = {
      powerManagement = {
        enable = true;
        finegrained = true; # CRITICAL for battery life
      };

      prime = {
        inherit (config.mySystem.nvidia) intelBusId nvidiaBusId;

        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        sync.enable = false;
      };
    };
  };
}
