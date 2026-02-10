# System stability, resource limits, and high-performance networking tuning.
{ lib, ... }:

{
  services = {
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 8; # 8% ≈ 2.6GB on 32GB (was 5%)
      freeSwapThreshold = 10;
      enableNotifications = true; # Desktop notification on kill
    };

    # Resolve conflict: earlyoom sets systembus-notify=true, smartd (via Scrutiny) sets false.
    # We want notifications enabled for earlyoom OOM-kill alerts.
    systembus-notify.enable = lib.mkForce true;
  };

  boot.kernel.sysctl = {
    "fs.file-max" = 1000000;
    "net.core.somaxconn" = 65536;
    "net.core.netdev_max_backlog" = 250000;
    "net.ipv4.tcp_max_syn_backlog" = 65536;
    "net.ipv4.ip_local_port_range" = "1024\t65535";
    "kernel.pid_max" = 4194303;
    "net.ipv4.tcp_fin_timeout" = 15;

    # TCP buffer tuning
    "net.core.rmem_max" = 16777216; # 16 MB
    "net.core.wmem_max" = 16777216; # 16 MB
    "net.ipv4.tcp_rmem" = "4096\t87380\t16777216";
    "net.ipv4.tcp_wmem" = "4096\t65536\t16777216";

    # Memory management
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50; # Keep dentries/inodes longer (good for dev work with large codebases)

    # TCP optimizations
    "net.ipv4.tcp_fastopen" = 3; # Client+server TFO (saves 1 RTT on HTTPS connections)
    "net.ipv4.tcp_mtu_probing" = 1; # Discover path MTU (helps on VPN tunnels like Mullvad)
  };

  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
    DefaultTimeoutStartSec = "30s";
    DefaultDeviceTimeoutSec = "30s";
    DefaultLimitNOFILE = 200000;
    DefaultLimitNPROC = 65536;
  };

  # PAM session limits (consolidated — includes core dump disable from security/hardening.nix)
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0"; # Disable core dumps (security hardening)
    }
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = 200000;
    }
    {
      domain = "*";
      type = "-";
      item = "nproc";
      value = 65536;
    }
    {
      domain = "*";
      type = "-";
      item = "stack";
      value = "65536"; # 64 MB
    }
  ];
}
