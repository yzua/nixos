# TLP power management for laptop.
{ config, lib, ... }:

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
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 50;

          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          # Platform power profile settings
          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";

          # CRITICAL for ThinkPad battery longevity (75-80% optimal range)
          START_CHARGE_THRESH_BAT0 = config.mySystem.laptop.battery.startChargeThreshold;
          STOP_CHARGE_THRESH_BAT0 = config.mySystem.laptop.battery.stopChargeThreshold;

          # Wireless power management
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";

          # Runtime power management for devices
          RUNTIME_PM_ON_AC = "on";
          RUNTIME_PM_ON_BAT = "auto";

          # Disk power management
          DISK_IDLE_SECS_ON_AC = 0;
          DISK_IDLE_SECS_ON_BAT = 2;

          # USB autosuspend (saves power)
          USB_AUTOSUSPEND = 1;
          USB_BLACKLIST_PHONE = 1;
          USB_EXCLUDE_BTUSB = 1;

          # AMD Radeon graphics power management (if applicable)
          RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
          RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

          # Disk I/O scheduler settings for SSDs
          DISK_IOSCHED = [ "none" ];

          # Additional power saving features
          RESTORE_DEVICE_STATE_ON_STARTUP = 1;
          DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan";
          DEVICES_TO_ENABLE_ON_STARTUP = "wifi";

          # PCIe Active State Power Management on battery
          PCIE_ASPM_ON_BAT = "powersupersave";

          # HDA Intel audio codec power saving on battery
          SOUND_POWER_SAVE_ON_BAT = 1; # 1-second timeout
          SOUND_POWER_SAVE_CONTROLLER = "Y"; # Also power down HDA controller

          # Disable NMI watchdog on battery (saves ~0.5W, not needed for non-debug)
          NMI_WATCHDOG = 0;

          # Intel graphics power (if applicable)
          INTEL_GPU_MIN_FREQ_ON_AC = 300;
          INTEL_GPU_MIN_FREQ_ON_BAT = 300;
          INTEL_GPU_MAX_FREQ_ON_AC = 1200;
          INTEL_GPU_MAX_FREQ_ON_BAT = 600;
        };
      };
    };
  };
}
