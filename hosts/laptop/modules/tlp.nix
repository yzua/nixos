# TLP power management for laptop.

{ config, lib, ... }:

let
  mkAcBatPair = key: acValue: batValue: {
    "${key}_ON_AC" = acValue;
    "${key}_ON_BAT" = batValue;
  };
in

{
  options.mySystem.laptop = {
    battery = {
      startChargeThreshold = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 75;
        example = 75;
        description = "Start charging battery when percentage falls below this value (1-100). 75-80% optimal for lithium-ion longevity.";
      };

      stopChargeThreshold = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 80;
        example = 80;
        description = "Stop charging battery when percentage reaches this value (1-100). Keep 10-20% below start threshold for battery health.";
      };
    };
  };

  config = {
    services = {
      tlp = {
        enable = true;

        settings = {
          # CPU Performance - CRITICAL for battery life
        }
        // (mkAcBatPair "CPU_SCALING_GOVERNOR" "performance" "powersave")
        // (mkAcBatPair "CPU_ENERGY_PERF_POLICY" "performance" "power")
        // {
          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 50;

          # Platform power profile settings

          # CRITICAL for ThinkPad battery longevity (75-80% optimal range)
          START_CHARGE_THRESH_BAT0 = config.mySystem.laptop.battery.startChargeThreshold;
          STOP_CHARGE_THRESH_BAT0 = config.mySystem.laptop.battery.stopChargeThreshold;

          # Wireless power management
          # Runtime power management for devices
          # Disk power management
          # USB autosuspend (saves power)
          USB_AUTOSUSPEND = 1;
          USB_BLACKLIST_PHONE = 1;
          USB_EXCLUDE_BTUSB = 1;

          # Disk I/O scheduler settings for SSDs
          DISK_IOSCHED = [ "none" ];

          # Additional power saving features
          RESTORE_DEVICE_STATE_ON_STARTUP = 1;
          DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";

          # PCIe Active State Power Management on battery
          PCIE_ASPM_ON_BAT = "powersupersave";

          # HDA Intel audio codec power saving on battery
          SOUND_POWER_SAVE_ON_BAT = 1; # 1-second timeout
          SOUND_POWER_SAVE_CONTROLLER = "Y"; # Also power down HDA controller

          # Disable NMI watchdog on battery (saves ~0.5W, not needed for non-debug)
          NMI_WATCHDOG = 0;

          # Intel graphics power (if applicable)
        }
        // (mkAcBatPair "CPU_BOOST" 1 0)
        // (mkAcBatPair "PLATFORM_PROFILE" "performance" "low-power")
        // (mkAcBatPair "WIFI_PWR" "off" "on")
        // (mkAcBatPair "RUNTIME_PM" "on" "auto")
        // (mkAcBatPair "DISK_IDLE_SECS" 0 2)
        // (mkAcBatPair "INTEL_GPU_MIN_FREQ" 300 300)
        // (mkAcBatPair "INTEL_GPU_MAX_FREQ" 1200 600);
      };
    };
  };
}
