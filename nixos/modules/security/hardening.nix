# Kernel and system security hardening (sysctl, AppArmor, PAM, hidepid).
{ lib, ... }:

{
  # GrapheneOS-inspired hardened allocator: guard pages, randomization, quarantine
  environment.memoryAllocator.provider = "graphene-hardened";

  services.logind.settings.Login = {
    IdleAction = "lock";
    IdleActionSec = 300; # seconds
  };

  boot.blacklistedKernelModules = [
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

  boot.kernel.sysctl = {
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
  };

  # lynis is in security/audit.nix (where the security-audit timer uses it)

  services.openssh.enable = false; # Desktop workstation — no remote access

  security = {
    apparmor.enable = true;
    protectKernelImage = true;

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
