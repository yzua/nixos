# Kernel and system security hardening (sysctl, AppArmor, PAM, hidepid).
{ lib, ... }:

{
  # graphene-hardened removed — crashes glycin/bwrap image loaders (Loupe, Nautilus
  # thumbnails) because the allocator is preloaded system-wide via ld-nix.so.preload
  # and glycin-image-rs sandbox children die with coredump signals.
  # Revisit if glycin upstream adds hardened-malloc compatibility.

  boot = {
    kernelParams = [
      # SECURITY: Disable vsyscall (legacy syscall interface, frequently exploited)
      "vsyscall=none"
      # SECURITY: Randomize kernel stack offset on syscall entry
      "randomize_kstack_offset=on"
      # SECURITY: Restrict access to kernel logs
      "loglevel=4"
    ];

    blacklistedKernelModules = [
      # Obscure network protocols (common exploit targets)
      "dccp"
      "sctp"
      "rds"
      "tipc"
      # FireWire/Thunderbolt (DMA attack vectors)
      "firewire-core"
      "firewire-ohci"
      "firewire-sbp2"
      "thunderbolt"
      # Virtual device attack surface
      "vivid" # Virtual video test driver (kernel attack surface)
      # Obscure filesystems
      "cramfs"
      "hfs"
      "hfsplus"
      "udf"
    ];

    kernel.sysctl = {
      # === Network Security ===
      "net.ipv4.tcp_syncookies" = 1; # SYN flood protection
      "net.ipv4.conf.all.rp_filter" = 2; # Loose mode — strict (1) breaks Docker/Mullvad routing
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Smurf attack prevention
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      # Disable ICMP redirects (MITM prevention)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Disable source routing (IP spoofing prevention)
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      "net.ipv4.conf.all.log_martians" = 1; # Log spoofed packets

      # IPv6 privacy extensions (defense-in-depth — IPv6 disabled in networking.nix)
      "net.ipv6.conf.all.use_tempaddr" = lib.mkForce 2;
      "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 2;

      # === Kernel Protection ===
      "kernel.kptr_restrict" = 2; # Hide kernel pointers
      "kernel.dmesg_restrict" = 1; # Root-only dmesg
      "kernel.yama.ptrace_scope" = 1; # Parent-only ptrace
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.core_pattern" = "|/bin/false";
      "kernel.sysrq" = 0; # Disable SysRq (physical attack vector)
      "fs.suid_dumpable" = 0;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.protected_hardlinks" = 1; # Prevent hardlink-based privilege escalation
      "fs.protected_symlinks" = 1; # Prevent symlink-based privilege escalation

      # PRIVACY: Prevent remote uptime fingerprinting
      "net.ipv4.tcp_timestamps" = 0;
      "kernel.perf_event_paranoid" = 3; # Prevent side-channel attacks
      "kernel.perf_cpu_time_max_percent" = 1; # Limit perf overhead
      "kernel.perf_event_max_sample_rate" = 1; # Restrict sampling rate

      # Exploit surface reduction
      "kernel.io_uring_disabled" = 2; # Disable io_uring (frequent exploit target, rarely needed on desktop)
      "vm.unprivileged_userfaultfd" = 0; # Restrict userfaultfd (used in exploit chains)

      # === IPv6 Neighbor Discovery Hardening ===
      "net.ipv6.conf.all.accept_ra" = 0; # Don't accept router advertisements
      "net.ipv6.conf.default.accept_ra" = 0;

      # === Additional Kernel Hardening ===
      "kernel.ftrace_enabled" = 0; # Disable function tracing (exploit tooling uses this)
      "net.ipv4.tcp_sack" = 0; # Disable TCP SACK (CVE-2019-11478 resource exhaustion)
      "net.ipv4.tcp_dsack" = 0; # Disable DACK (related to SACK)
      "net.ipv4.tcp_fack" = 0; # Disable Forward ACK

      # === Enhanced ASLR ===
      # Maximize address space randomization for 64-bit (28 bits = 256MB range)
      "vm.mmap_rnd_bits" = 28;
      "vm.mmap_rnd_compat_bits" = 8;
    };
  };

  services.logind.settings.Login = {
    IdleAction = "lock";
    IdleActionSec = 300; # seconds
    HandleLidSwitch = "lock"; # Lock on lid close (laptop)
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "lock";
  };

  security = {
    apparmor.enable = true;
    protectKernelImage = true;
    lockKernelModules = true; # Prevent loading kernel modules after boot (reduces attack surface)

    sudo = {
      enable = true;
      wheelNeedsPassword = true;
      execWheelOnly = true;
      extraConfig = ''
        # SECURITY: Log all sudo commands for audit trail
        Defaults use_pty
        Defaults log_input
        Defaults log_output
        Defaults logfile="/var/log/sudo.log"
      '';
    };

    # Audit disabled — AppArmor + auditd kernel interaction causes
    # audit_log_subj_ctx panics on newer kernels
    auditd.enable = false;
    audit.enable = false;
  };

  # /proc hardening — hide other users' processes
  fileSystems."/proc" = {
    device = "proc";
    fsType = "proc";
    options = [
      "defaults"
      "hidepid=2"
    ];
    neededForBoot = true;
  };

  systemd.coredump.enable = false;
}
