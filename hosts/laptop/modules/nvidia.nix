# NVIDIA Optimus (hybrid graphics) for ThinkPad.
{ config, lib, ... }:

let
  mkBusIdOption =
    description: default:
    lib.mkOption {
      type = lib.types.str;
      inherit default description;
      example = "PCI:0:2:0:0";
    };
in

{
  options.mySystem.nvidia = {
    intelBusId = mkBusIdOption "Intel GPU PCI bus ID (format: PCI:bus:device:function)." "PCI:0:2:0:0";

    nvidiaBusId = mkBusIdOption "NVIDIA GPU PCI bus ID (format: PCI:bus:device:function)." "PCI:2:0:0:0";
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
