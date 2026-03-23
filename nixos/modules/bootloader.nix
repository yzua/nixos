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

      # === Kernel Memory Hardening ===
      "page_alloc.shuffle=1" # ASLR for page allocator
      "randomize_kstack_offset=on" # Randomize kernel stack offset per syscall
      "vsyscall=none" # Disable legacy vsyscall (attack surface reduction)
      "slab_nomerge" # Prevent slab cache merging (stops heap exploitation)
      "init_on_alloc=1" # Zero memory on allocation (prevents info leaks)
      "init_on_free=1" # Zero memory on free (prevents use-after-free data)
      "module.sig_enforce=1" # Only load signed kernel modules
      "lockdown=confidentiality" # Kernel lockdown: restrict /dev/mem, kexec, etc.

      # === Suspend Hardening (desktop) ===
      "mem_sleep_default=deep" # Prefer deep sleep (full S3) over s2idle

      # === RNG Hardening ===
      "random.trust_cpu=off" # Don't trust CPU RNG (RDRAND) — use entropy pool
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
