# Bootloader configuration (systemd-boot).

{ pkgsStable, ... }:
{
  boot = {
    kernelPackages = pkgsStable.linuxPackages_6_18;

    loader = {
      timeout = 2; # Show generation menu briefly (hold Space to pause and select)
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        editor = false; # SECURITY: Prevent editing boot entries (root shell via init=/bin/sh)
        configurationLimit = 10;
      };
    };

    # PRIVACY: RAM-backed /tmp so temp files don't persist on disk
    tmp = {
      useTmpfs = true;
      tmpfsSize = "50%";
    };

    # Silent boot
    kernelParams = [
      "quiet"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      # SECURITY: shell_on_fail omitted — drops to root shell on failure
      # SECURITY: Kernel memory/suspend/RNG hardening params live in security/hardening.nix
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
