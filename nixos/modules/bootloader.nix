# Bootloader configuration (systemd-boot).
{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;

    loader = {
      timeout = 5; # Show generation menu for 5 seconds (hold Space to pause)
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
      # SECURITY: Kernel hardening (no boot time cost)
      "page_alloc.shuffle=1" # ASLR for page allocator
      "randomize_kstack_offset=on" # Randomize kernel stack offset per syscall
      "vsyscall=none" # Disable legacy vsyscall (attack surface reduction)
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
